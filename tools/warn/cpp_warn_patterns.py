# python3
# Copyright (C) 2019 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Warning patterns for C/C++ compiler, but not clang-tidy."""

# No need of doc strings for trivial small functions.
# pylint:disable=missing-function-docstring

import re

# pylint:disable=relative-beyond-top-level
from .severity import Severity


def cpp_warn(severity, description, pattern_list):
  return {
      'category': 'C/C++',
      'severity': severity,
      'description': description,
      'patterns': pattern_list
  }


def fixmenow(description, pattern_list):
  return cpp_warn(Severity.FIXMENOW, description, pattern_list)


def high(description, pattern_list):
  return cpp_warn(Severity.HIGH, description, pattern_list)


def medium(description, pattern_list):
  return cpp_warn(Severity.MEDIUM, description, pattern_list)


def low(description, pattern_list):
  return cpp_warn(Severity.LOW, description, pattern_list)


def skip(description, pattern_list):
  return cpp_warn(Severity.SKIP, description, pattern_list)


def harmless(description, pattern_list):
  return cpp_warn(Severity.HARMLESS, description, pattern_list)


warn_patterns = [
    # pylint does not recognize g-inconsistent-quotes
    # pylint:disable=line-too-long,bad-option-value,g-inconsistent-quotes
    medium('Implicit function declaration',
           [r".*: warning: implicit declaration of function .+",
            r".*: warning: implicitly declaring library function"]),
    skip('skip, conflicting types for ...',
         [r".*: warning: conflicting types for '.+'"]),
    high('Expression always evaluates to true or false',
         [r".*: warning: comparison is always .+ due to limited range of data type",
          r".*: warning: comparison of unsigned .*expression .+ is always true",
          r".*: warning: comparison of unsigned .*expression .+ is always false"]),
    high('Use transient memory for control value',
         [r".*: warning: .+Using such transient memory for the control value is .*dangerous."]),
    high('Return address of stack memory',
         [r".*: warning: Address of stack memory .+ returned to caller",
          r".*: warning: Address of stack memory .+ will be a dangling reference"]),
    high('Infinite recursion',
         [r".*: warning: all paths through this function will call itself"]),
    high('Potential buffer overflow',
         [r".*: warning: Size argument is greater than .+ the destination buffer",
          r".*: warning: Potential buffer overflow.",
          r".*: warning: String copy function overflows destination buffer"]),
    medium('Incompatible pointer types',
           [r".*: warning: assignment from incompatible pointer type",
            r".*: warning: return from incompatible pointer type",
            r".*: warning: passing argument [0-9]+ of '.*' from incompatible pointer type",
            r".*: warning: initialization from incompatible pointer type"]),
    high('Incompatible declaration of built in function',
         [r".*: warning: incompatible implicit declaration of built-in function .+"]),
    high('Incompatible redeclaration of library function',
         [r".*: warning: incompatible redeclaration of library function .+"]),
    high('Null passed as non-null argument',
         [r".*: warning: Null passed to a callee that requires a non-null"]),
    medium('Unused parameter',
           [r".*: warning: unused parameter '.*'"]),
    medium('Unused function, variable, label, comparison, etc.',
           [r".*: warning: '.+' defined but not used",
            r".*: warning: unused function '.+'",
            r".*: warning: unused label '.+'",
            r".*: warning: relational comparison result unused",
            r".*: warning: lambda capture .* is not used",
            r".*: warning: private field '.+' is not used",
            r".*: warning: unused variable '.+'"]),
    medium('Statement with no effect or result unused',
           [r".*: warning: statement with no effect",
            r".*: warning: expression result unused"]),
    medium('Ignoreing return value of function',
           [r".*: warning: ignoring return value of function .+Wunused-result"]),
    medium('Missing initializer',
           [r".*: warning: missing initializer"]),
    medium('Need virtual destructor',
           [r".*: warning: delete called .* has virtual functions but non-virtual destructor"]),
    skip('skip, near initialization for ...',
         [r".*: warning: \(near initialization for '.+'\)"]),
    medium('Expansion of data or time macro',
           [r".*: warning: expansion of date or time macro is not reproducible"]),
    medium('Macro expansion has undefined behavior',
           [r".*: warning: macro expansion .* has undefined behavior"]),
    medium('Format string does not match arguments',
           [r".*: warning: format '.+' expects type '.+', but argument [0-9]+ has type '.+'",
            r".*: warning: more '%' conversions than data arguments",
            r".*: warning: data argument not used by format string",
            r".*: warning: incomplete format specifier",
            r".*: warning: unknown conversion type .* in format",
            r".*: warning: format .+ expects .+ but argument .+Wformat=",
            r".*: warning: field precision should have .+ but argument has .+Wformat",
            r".*: warning: format specifies type .+ but the argument has .*type .+Wformat"]),
    medium('Too many arguments for format string',
           [r".*: warning: too many arguments for format"]),
    medium('Too many arguments in call',
           [r".*: warning: too many arguments in call to "]),
    medium('Invalid format specifier',
           [r".*: warning: invalid .+ specifier '.+'.+format-invalid-specifier"]),
    medium('Comparison between signed and unsigned',
           [r".*: warning: comparison between signed and unsigned",
            r".*: warning: comparison of promoted \~unsigned with unsigned",
            r".*: warning: signed and unsigned type in conditional expression"]),
    medium('Comparison between enum and non-enum',
           [r".*: warning: enumeral and non-enumeral type in conditional expression"]),
    medium('libpng: zero area',
           [r".*libpng warning: Ignoring attempt to set cHRM RGB triangle with zero area"]),
    medium('Missing braces around initializer',
           [r".*: warning: missing braces around initializer.*"]),
    harmless('No newline at end of file',
             [r".*: warning: no newline at end of file"]),
    harmless('Missing space after macro name',
             [r".*: warning: missing whitespace after the macro name"]),
    low('Cast increases required alignment',
        [r".*: warning: cast from .* to .* increases required alignment .*"]),
    medium('Qualifier discarded',
           [r".*: warning: passing argument [0-9]+ of '.+' discards qualifiers from pointer target type",
            r".*: warning: assignment discards qualifiers from pointer target type",
            r".*: warning: passing .+ to parameter of type .+ discards qualifiers",
            r".*: warning: assigning to .+ from .+ discards qualifiers",
            r".*: warning: initializing .+ discards qualifiers .+types-discards-qualifiers",
            r".*: warning: return discards qualifiers from pointer target type"]),
    medium('Unknown attribute',
           [r".*: warning: unknown attribute '.+'"]),
    medium('Attribute ignored',
           [r".*: warning: '_*packed_*' attribute ignored",
            r".*: warning: .* not supported .*Wignored-attributes",
            r".*: warning: attribute declaration must precede definition .+ignored-attributes"]),
    medium('Visibility problem',
           [r".*: warning: declaration of '.+' will not be visible outside of this function"]),
    medium('Visibility mismatch',
           [r".*: warning: '.+' declared with greater visibility than the type of its field '.+'"]),
    medium('Shift count greater than width of type',
           [r".*: warning: (left|right) shift count >= width of type"]),
    medium('extern &lt;foo&gt; is initialized',
           [r".*: warning: '.+' initialized and declared 'extern'",
            r".*: warning: 'extern' variable has an initializer"]),
    medium('Old style declaration',
           [r".*: warning: 'static' is not at beginning of declaration"]),
    medium('Missing return value',
           [r".*: warning: control reaches end of non-void function"]),
    medium('Implicit int type',
           [r".*: warning: type specifier missing, defaults to 'int'",
            r".*: warning: type defaults to 'int' in declaration of '.+'"]),
    medium('Main function should return int',
           [r".*: warning: return type of 'main' is not 'int'"]),
    medium('Variable may be used uninitialized',
           [r".*: warning: '.+' may be used uninitialized in this function"]),
    high('Variable is used uninitialized',
         [r".*: warning: '.+' is used uninitialized in this function",
          r".*: warning: variable '.+' is uninitialized when used here"]),
    medium('ld: possible enum size mismatch',
           [r".*: warning: .* uses variable-size enums yet the output is to use 32-bit enums; use of enum values across objects may fail"]),
    medium('Pointer targets differ in signedness',
           [r".*: warning: pointer targets in initialization differ in signedness",
            r".*: warning: pointer targets in assignment differ in signedness",
            r".*: warning: pointer targets in return differ in signedness",
            r".*: warning: pointer targets in passing argument [0-9]+ of '.+' differ in signedness"]),
    medium('Assuming overflow does not occur',
           [r".*: warning: assuming signed overflow does not occur when assuming that .* is always (true|false)"]),
    medium('Suggest adding braces around empty body',
           [r".*: warning: suggest braces around empty body in an 'if' statement",
            r".*: warning: empty body in an if-statement",
            r".*: warning: suggest braces around empty body in an 'else' statement",
            r".*: warning: empty body in an else-statement"]),
    medium('Suggest adding parentheses',
           [r".*: warning: suggest explicit braces to avoid ambiguous 'else'",
            r".*: warning: suggest parentheses around arithmetic in operand of '.+'",
            r".*: warning: suggest parentheses around comparison in operand of '.+'",
            r".*: warning: logical not is only applied to the left hand side of this comparison",
            r".*: warning: using the result of an assignment as a condition without parentheses",
            r".*: warning: .+ has lower precedence than .+ be evaluated first .+Wparentheses",
            r".*: warning: suggest parentheses around '.+?' .+ '.+?'",
            r".*: warning: suggest parentheses around assignment used as truth value"]),
    medium('Static variable used in non-static inline function',
           [r".*: warning: '.+' is static but used in inline function '.+' which is not static"]),
    medium('No type or storage class (will default to int)',
           [r".*: warning: data definition has no type or storage class"]),
    skip('skip, parameter name (without types) in function declaration',
         [r".*: warning: parameter names \(without types\) in function declaration"]),
    medium('Dereferencing &lt;foo&gt; breaks strict aliasing rules',
           [r".*: warning: dereferencing .* break strict-aliasing rules"]),
    medium('Cast from pointer to integer of different size',
           [r".*: warning: cast from pointer to integer of different size",
            r".*: warning: initialization makes pointer from integer without a cast"]),
    medium('Cast to pointer from integer of different size',
           [r".*: warning: cast to pointer from integer of different size"]),
    medium('Macro redefined',
           [r".*: warning: '.+' macro redefined"]),
    skip('skip, ... location of the previous definition',
         [r".*: warning: this is the location of the previous definition"]),
    medium('ld: type and size of dynamic symbol are not defined',
           [r".*: warning: type and size of dynamic symbol `.+' are not defined"]),
    medium('Pointer from integer without cast',
           [r".*: warning: assignment makes pointer from integer without a cast"]),
    medium('Pointer from integer without cast',
           [r".*: warning: passing argument [0-9]+ of '.+' makes pointer from integer without a cast"]),
    medium('Integer from pointer without cast',
           [r".*: warning: assignment makes integer from pointer without a cast"]),
    medium('Integer from pointer without cast',
           [r".*: warning: passing argument [0-9]+ of '.+' makes integer from pointer without a cast"]),
    medium('Integer from pointer without cast',
           [r".*: warning: return makes integer from pointer without a cast"]),
    medium('Ignoring pragma',
           [r".*: warning: ignoring #pragma .+"]),
    medium('Pragma warning messages',
           [r".*: warning: .+W#pragma-messages"]),
    medium('Variable might be clobbered by longjmp or vfork',
           [r".*: warning: variable '.+' might be clobbered by 'longjmp' or 'vfork'"]),
    medium('Argument might be clobbered by longjmp or vfork',
           [r".*: warning: argument '.+' might be clobbered by 'longjmp' or 'vfork'"]),
    medium('Redundant declaration',
           [r".*: warning: redundant redeclaration of '.+'"]),
    skip('skip, previous declaration ... was here',
         [r".*: warning: previous declaration of '.+' was here"]),
    high('Enum value not handled in switch',
         [r".*: warning: .*enumeration value.* not handled in switch.+Wswitch"]),
    medium('User defined warnings',
           [r".*: warning: .* \[-Wuser-defined-warnings\]$"]),
    medium('Taking address of temporary',
           [r".*: warning: taking address of temporary"]),
    medium('Taking address of packed member',
           [r".*: warning: taking address of packed member"]),
    medium('Pack alignment value is modified',
           [r".*: warning: .*#pragma pack alignment value is modified.*Wpragma-pack.*"]),
    medium('Possible broken line continuation',
           [r".*: warning: backslash and newline separated by space"]),
    medium('Undefined variable template',
           [r".*: warning: instantiation of variable .* no definition is available"]),
    medium('Inline function is not defined',
           [r".*: warning: inline function '.*' is not defined"]),
    medium('Excess elements in initializer',
           [r".*: warning: excess elements in .+ initializer"]),
    medium('Decimal constant is unsigned only in ISO C90',
           [r".*: warning: this decimal constant is unsigned only in ISO C90"]),
    medium('main is usually a function',
           [r".*: warning: 'main' is usually a function"]),
    medium('Typedef ignored',
           [r".*: warning: 'typedef' was ignored in this declaration"]),
    high('Address always evaluates to true',
         [r".*: warning: the address of '.+' will always evaluate as 'true'"]),
    fixmenow('Freeing a non-heap object',
             [r".*: warning: attempt to free a non-heap object '.+'"]),
    medium('Array subscript has type char',
           [r".*: warning: array subscript .+ type 'char'.+Wchar-subscripts"]),
    medium('Constant too large for type',
           [r".*: warning: integer constant is too large for '.+' type"]),
    medium('Constant too large for type, truncated',
           [r".*: warning: large integer implicitly truncated to unsigned type"]),
    medium('Overflow in expression',
           [r".*: warning: overflow in expression; .*Winteger-overflow"]),
    medium('Overflow in implicit constant conversion',
           [r".*: warning: overflow in implicit constant conversion"]),
    medium('Declaration does not declare anything',
           [r".*: warning: declaration 'class .+' does not declare anything"]),
    medium('Initialization order will be different',
           [r".*: warning: '.+' will be initialized after",
            r".*: warning: field .+ will be initialized after .+Wreorder"]),
    skip('skip,   ....',
         [r".*: warning:   '.+'"]),
    skip('skip,   base ...',
         [r".*: warning:   base '.+'"]),
    skip('skip,   when initialized here',
         [r".*: warning:   when initialized here"]),
    medium('Parameter type not specified',
           [r".*: warning: type of '.+' defaults to 'int'"]),
    medium('Missing declarations',
           [r".*: warning: declaration does not declare anything"]),
    medium('Missing noreturn',
           [r".*: warning: function '.*' could be declared with attribute 'noreturn'"]),
    medium('User warning',
           [r".*: warning: #warning \".+\""]),
    medium('Vexing parsing problem',
           [r".*: warning: empty parentheses interpreted as a function declaration"]),
    medium('Dereferencing void*',
           [r".*: warning: dereferencing 'void \*' pointer"]),
    medium('Comparison of pointer and integer',
           [r".*: warning: ordered comparison of pointer with integer zero",
            r".*: warning: .*comparison between pointer and integer"]),
    medium('Use of error-prone unary operator',
           [r".*: warning: use of unary operator that may be intended as compound assignment"]),
    medium('Conversion of string constant to non-const char*',
           [r".*: warning: deprecated conversion from string constant to '.+'"]),
    medium('Function declaration isn''t a prototype',
           [r".*: warning: function declaration isn't a prototype"]),
    medium('Type qualifiers ignored on function return value',
           [r".*: warning: type qualifiers ignored on function return type",
            r".*: warning: .+ type qualifier .+ has no effect .+Wignored-qualifiers"]),
    medium('&lt;foo&gt; declared inside parameter list, scope limited to this definition',
           [r".*: warning: '.+' declared inside parameter list"]),
    skip('skip, its scope is only this ...',
         [r".*: warning: its scope is only this definition or declaration, which is probably not what you want"]),
    low('Line continuation inside comment',
        [r".*: warning: multi-line comment"]),
    low('Comment inside comment',
        [r".*: warning: '.+' within block comment .*-Wcomment"]),
    low('Deprecated declarations',
        [r".*: warning: .+ is deprecated.+deprecated-declarations"]),
    low('Deprecated register',
        [r".*: warning: 'register' storage class specifier is deprecated"]),
    low('Converts between pointers to integer types with different sign',
        [r".*: warning: .+ converts between pointers to integer types with different sign"]),
    harmless('Extra tokens after #endif',
             [r".*: warning: extra tokens at end of #endif directive"]),
    medium('Comparison between different enums',
           [r".*: warning: comparison between '.+' and '.+'.+Wenum-compare",
            r".*: warning: comparison of .* enumeration types .*-Wenum-compare.*"]),
    medium('Conversion may change value',
           [r".*: warning: converting negative value '.+' to '.+'",
            r".*: warning: conversion to '.+' .+ may (alter|change)"]),
    medium('Converting to non-pointer type from NULL',
           [r".*: warning: converting to non-pointer type '.+' from NULL"]),
    medium('Implicit sign conversion',
           [r".*: warning: implicit conversion changes signedness"]),
    medium('Converting NULL to non-pointer type',
           [r".*: warning: implicit conversion of NULL constant to '.+'"]),
    medium('Zero used as null pointer',
           [r".*: warning: expression .* zero treated as a null pointer constant"]),
    medium('Compare pointer to null character',
           [r".*: warning: comparing a pointer to a null character constant"]),
    medium('Implicit conversion changes value or loses precision',
           [r".*: warning: implicit conversion .* changes value from .* to .*-conversion",
            r".*: warning: implicit conversion loses integer precision:"]),
    medium('Passing NULL as non-pointer argument',
           [r".*: warning: passing NULL to non-pointer argument [0-9]+ of '.+'"]),
    medium('Class seems unusable because of private ctor/dtor',
           [r".*: warning: all member functions in class '.+' are private"]),
    # skip this next one, because it only points out some RefBase-based classes
    # where having a private destructor is perfectly fine
    skip('Class seems unusable because of private ctor/dtor',
         [r".*: warning: 'class .+' only defines a private destructor and has no friends"]),
    medium('Class seems unusable because of private ctor/dtor',
           [r".*: warning: 'class .+' only defines private constructors and has no friends"]),
    medium('In-class initializer for static const float/double',
           [r".*: warning: in-class initializer for static data member of .+const (float|double)"]),
    medium('void* used in arithmetic',
           [r".*: warning: pointer of type 'void \*' used in (arithmetic|subtraction)",
            r".*: warning: arithmetic on .+ to void is a GNU extension.*Wpointer-arith",
            r".*: warning: wrong type argument to increment"]),
    medium('Overload resolution chose to promote from unsigned or enum to signed type',
           [r".*: warning: passing '.+' chooses '.+' over '.+'.*Wsign-promo"]),
    skip('skip,   in call to ...',
         [r".*: warning:   in call to '.+'"]),
    high('Base should be explicitly initialized in copy constructor',
         [r".*: warning: base class '.+' should be explicitly initialized in the copy constructor"]),
    medium('Return value from void function',
           [r".*: warning: 'return' with a value, in function returning void"]),
    medium('Multi-character character constant',
           [r".*: warning: multi-character character constant"]),
    medium('Conversion from string literal to char*',
           [r".*: warning: .+ does not allow conversion from string literal to 'char \*'"]),
    low('Extra \';\'',
        [r".*: warning: extra ';' .+extra-semi"]),
    low('Useless specifier',
        [r".*: warning: useless storage class specifier in empty declaration"]),
    low('Duplicate declaration specifier',
        [r".*: warning: duplicate '.+' declaration specifier"]),
    low('Comparison of self is always false',
        [r".*: self-comparison always evaluates to false"]),
    low('Logical op with constant operand',
        [r".*: use of logical '.+' with constant operand"]),
    low('Needs a space between literal and string macro',
        [r".*: warning: invalid suffix on literal.+ requires a space .+Wliteral-suffix"]),
    low('Warnings from #warning',
        [r".*: warning: .+-W#warnings"]),
    low('Using float/int absolute value function with int/float argument',
        [r".*: warning: using .+ absolute value function .+ when argument is .+ type .+Wabsolute-value",
         r".*: warning: absolute value function '.+' given .+ which may cause truncation .+Wabsolute-value"]),
    low('Using C++11 extensions',
        [r".*: warning: 'auto' type specifier is a C\+\+11 extension"]),
    low('Using C++17 extensions',
        [r".*: warning: .* a C\+\+17 extension .+Wc\+\+17-extensions"]),
    low('Refers to implicitly defined namespace',
        [r".*: warning: using directive refers to implicitly-defined namespace .+"]),
    low('Invalid pp token',
        [r".*: warning: missing .+Winvalid-pp-token"]),
    low('need glibc to link',
        [r".*: warning: .* requires at runtime .* glibc .* for linking"]),
    medium('Operator new returns NULL',
           [r".*: warning: 'operator new' must not return NULL unless it is declared 'throw\(\)' .+"]),
    medium('NULL used in arithmetic',
           [r".*: warning: NULL used in arithmetic",
            r".*: warning: comparison between NULL and non-pointer"]),
    medium('Misspelled header guard',
           [r".*: warning: '.+' is used as a header guard .+ followed by .+ different macro"]),
    medium('Empty loop body',
           [r".*: warning: .+ loop has empty body"]),
    medium('Implicit conversion from enumeration type',
           [r".*: warning: implicit conversion from enumeration type '.+'"]),
    medium('case value not in enumerated type',
           [r".*: warning: case value not in enumerated type '.+'"]),
    medium('Use of deprecated method',
           [r".*: warning: '.+' is deprecated .+"]),
    medium('Use of garbage or uninitialized value',
           [r".*: warning: .+ uninitialized .+\[-Wsometimes-uninitialized\]"]),
    medium('Sizeof on array argument',
           [r".*: warning: sizeof on array function parameter will return"]),
    medium('Bad argument size of memory access functions',
           [r".*: warning: .+\[-Wsizeof-pointer-memaccess\]"]),
    medium('Return value not checked',
           [r".*: warning: The return value from .+ is not checked"]),
    medium('Possible heap pollution',
           [r".*: warning: .*Possible heap pollution from .+ type .+"]),
    medium('Variable used in loop condition not modified in loop body',
           [r".*: warning: variable '.+' used in loop condition.*Wfor-loop-analysis"]),
    medium('Closing a previously closed file',
           [r".*: warning: Closing a previously closed file"]),
    medium('Unnamed template type argument',
           [r".*: warning: template argument.+Wunnamed-type-template-args"]),
    medium('Unannotated fall-through between switch labels',
           [r".*: warning: unannotated fall-through between switch labels.+Wimplicit-fallthrough"]),
    medium('Invalid partial specialization',
           [r".*: warning: class template partial specialization.+Winvalid-partial-specialization"]),
    medium('Overlapping comparisons',
           [r".*: warning: overlapping comparisons.+Wtautological-overlap-compare"]),
    medium('bitwise comparison',
           [r".*: warning: bitwise comparison.+Wtautological-bitwise-compare"]),
    medium('int in bool context',
           [r".*: warning: converting.+to a boolean.+Wint-in-bool-context"]),
    medium('bitwise conditional parentheses',
           [r".*: warning: operator.+has lower precedence.+Wbitwise-conditional-parentheses"]),
    medium('sizeof array div',
           [r".*: warning: .+number of elements in.+array.+Wsizeof-array-div"]),
    medium('bool operation',
           [r".*: warning: .+boolean.+always.+Wbool-operation"]),
    medium('Undefined bool conversion',
           [r".*: warning: .+may be.+always.+true.+Wundefined-bool-conversion"]),
    medium('Typedef requires a name',
           [r".*: warning: typedef requires a name.+Wmissing-declaration"]),
    medium('Unknown escape sequence',
           [r".*: warning: unknown escape sequence.+Wunknown-escape-sequence"]),
    medium('Unicode whitespace',
           [r".*: warning: treating Unicode.+as whitespace.+Wunicode-whitespace"]),
    medium('Unused local typedef',
           [r".*: warning: unused typedef.+Wunused-local-typedef"]),
    medium('varargs warnings',
           [r".*: warning: .*argument to 'va_start'.+\[-Wvarargs\]"]),
    harmless('Discarded qualifier from pointer target type',
             [r".*: warning: .+ discards '.+' qualifier from pointer target type"]),
    harmless('Use snprintf instead of sprintf',
             [r".*: warning: .*sprintf is often misused; please use snprintf"]),
    harmless('Unsupported optimizaton flag',
             [r".*: warning: optimization flag '.+' is not supported"]),
    harmless('Extra or missing parentheses',
             [r".*: warning: equality comparison with extraneous parentheses",
              r".*: warning: .+ within .+Wlogical-op-parentheses"]),
    harmless('Mismatched class vs struct tags',
             [r".*: warning: '.+' defined as a .+ here but previously declared as a .+mismatched-tags",
              r".*: warning: .+ was previously declared as a .+mismatched-tags"]),
]


def compile_patterns(patterns):
  """Precompiling every pattern speeds up parsing by about 30x."""
  for i in patterns:
    i['compiled_patterns'] = []
    for pat in i['patterns']:
      i['compiled_patterns'].append(re.compile(pat))


compile_patterns(warn_patterns)
