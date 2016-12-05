#!/usr/bin/env python
# -*- coding: utf-8 -*-

## This file contains a modification of code in `main.py` from the mathics distribution
## 1.0 by the mathics project.

from __future__ import unicode_literals
from __future__ import print_function
from __future__ import absolute_import

import sys
import os
import argparse
import re
import locale

from mathics.core.definitions import Definitions
from mathics.core.expression import strip_context
from mathics.core.evaluation import Evaluation, Output
from mathics.core.parser import LineFeeder, FileLineFeeder
from mathics import version_string, license_string, __version__
from mathics import settings

from mathics.main import TerminalOutput

import six
from six.moves import input


class SymataTerminalShell(LineFeeder):
    def __init__(self, definitions, colors, want_readline, want_completion):
        super(SymataTerminalShell, self).__init__('<stdin>')
        self.input_encoding = locale.getpreferredencoding()
        self.lineno = 0
        self.inputno = 0

        # Try importing readline to enable arrow keys support etc.
        self.using_readline = False
        try:
            if want_readline:
                import readline
                self.using_readline = sys.stdin.isatty() and sys.stdout.isatty()
                self.ansi_color_re = re.compile("\033\\[[0-9;]+m")
                if want_completion:
                    readline.set_completer(lambda text, state: self.complete_symbol_name(text, state))

                    # Make _ a delimiter, but not $ or `
                    readline.set_completer_delims(' \t\n_~!@#%^&*()-=+[{]}\\|;:\'",<>/?')

                    readline.parse_and_bind("tab: complete")
                    self.completion_candidates = []
        except ImportError:
            pass

        # Try importing colorama to escape ansi sequences for cross platform
        # colors
        try:
            from colorama import init as colorama_init
        except ImportError:
            colors = 'NoColor'
        else:
            colorama_init()
            if colors is None:
                terminal_supports_color = (sys.stdout.isatty() and os.getenv('TERM') != 'dumb')
                colors = 'Linux' if terminal_supports_color else 'NoColor'

        color_schemes = {
            'NOCOLOR': (
                ['', '', '', ''],
                ['', '', '', '']),
            'LINUX': (
                ['\033[32m', '\033[1m', '\033[22m', '\033[39m'],
                ['\033[31m', '\033[1m', '\033[22m', '\033[39m']),
            'LIGHTBG': (
                ['\033[34m', '\033[1m', '\033[22m', '\033[39m'],
                ['\033[31m', '\033[1m', '\033[22m', '\033[39m']),
        }

        # Handle any case by using .upper()
        term_colors = color_schemes.get(colors.upper())
        if term_colors is None:
            out_msg = "The 'colors' argument must be {0} or None"
            print(out_msg.format(repr(list(color_schemes.keys()))))
            quit()

        self.incolors, self.outcolors = term_colors
        self.definitions = definitions

    def get_last_line_number(self):
        return self.definitions.get_line_no()

    def get_in_prompt(self):
        next_line_number = self.get_last_line_number() + 1
        if self.lineno > 0:
            return ' ' * len('In[{0}]:= '.format(next_line_number))
        else:
            return '{1}In[{2}{0}{3}]:= {4}'.format(next_line_number, *self.incolors)

    def get_out_prompt(self):
        line_number = self.get_last_line_number()
        return '{1}Out[{2}{0}{3}]= {4}'.format(line_number, *self.outcolors)

    def to_output(self, text):
        line_number = self.get_last_line_number()
        newline = '\n' + ' ' * len('Out[{0}]= '.format(line_number))
        return newline.join(text.splitlines())

    def out_callback(self, out):
        print(self.to_output(six.text_type(out)))

    def read_line(self, prompt):
        if self.using_readline:
            return self.rl_read_line(prompt)
        return input(prompt)

    def print_result(self, result):
        if result is not None and result.result is not None:
            output = self.to_output(six.text_type(result.result))
            print(self.get_out_prompt() + output + '\n')

    def rl_read_line(self, prompt):
        # Wrap ANSI colour sequences in \001 and \002, so readline
        # knows that they're nonprinting.
        prompt = self.ansi_color_re.sub(
            lambda m: "\001" + m.group(0) + "\002", prompt)

        # For Py2 sys.stdout is wrapped by a codecs.StreamWriter object in
        # mathics/__init__.py which interferes with raw_input's use of readline
        #
        # To work around this issue, call raw_input with the original
        # file object as sys.stdout, which is in the undocumented
        # 'stream' field of codecs.StreamWriter.
        if six.PY2:
            orig_stdout = sys.stdout
            try:
                sys.stdout = sys.stdout.stream
                ret = input(prompt).decode(self.input_encoding)
                return ret
            finally:
                sys.stdout = orig_stdout
        else:
            return input(prompt)

    def complete_symbol_name(self, text, state):
        try:
            return self._complete_symbol_name(text, state)
        except Exception:
            # any exception thrown inside the completer gets silently
            # thrown away otherwise
            print("Unhandled error in readline completion")

    def _complete_symbol_name(self, text, state):
        # The readline module calls this function repeatedly,
        # increasing 'state' each time and expecting one string to be
        # returned per call.

        if state == 0:
            self.completion_candidates = self.get_completion_candidates(text)

        try:
            return self.completion_candidates[state]
        except IndexError:
            return None

    def get_completion_candidates(self, text):
        matches = self.definitions.get_matching_names(text + '*')
        if '`' not in text:
            matches = [strip_context(m) for m in matches]
        return matches

    def reset_lineno(self):
        self.lineno = 0

    def set_inputno(self,n):
        self.inputno = n

    def get_symata_in_prompt(self):
        if self.lineno > 0:
            return ' ' * len('In[{0}]:= '.format(self.inputno))
        else:
            return '{1}In[{2}{0}{3}]:= {4}'.format(self.inputno, *self.incolors)

    def feed(self):
        result = self.read_line(self.get_symata_in_prompt()) + '\n'
        if result == '\n':
            return ''   # end of input
        self.lineno += 1
        return result

    def empty(self):
        return False


def mathics_shell(shell):
    while True:
        try:
            evaluation = Evaluation(shell.definitions, output=TerminalOutput(shell))
            query = evaluation.parse_feeder(shell)
            if query is None:
                continue
            result = evaluation.evaluate(query, timeout=settings.TIMEOUT)
            if result is not None:
                shell.print_result(result)
        except (KeyboardInterrupt):
            print('\nKeyboardInterrupt')
        except (SystemExit, EOFError):
            break
        finally:
            shell.reset_lineno()
