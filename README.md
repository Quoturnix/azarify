# Azarify
Easter Egg language processor. Teach your userbase to speak French automagically. 

## How does it work?
Use this software to generate the glue code that would replace words in the input strings based
on the substitution rules, which consist of both word-to-word substitutions, enging-to-ending ones
and a stop list of words that should not be replaced. "I worked" becomes "Je worké". You get the idea.

## Dependencies
Make sure you have Lua 5+ installed. You proably do though.

## Usage
```
./azarify [-q|-s|-v] [-g|-p] \
    [-o output-file] [-f frequencies-file] \
    [-i [input-file] [rules-file] 
```
* `-g` runs the code generation mode, producing includable glue code source, `-p` is the default mode and just 
processes the input in accordance to rules;
* `-v` shows statistics about substitutions made on the standard error stream and is the default, `-s` acts 
likewise, but only prints a single number as a ratio rather than a percentage, `-v` suppresses any statistical
output. Neither key is meaningful in `-g` mode;
* `-f` outputs frequencies of the words encountered in the CSV file specified by `frequencies-file`, has no
meaning in `-g` mode;
* `rules-file` is the lua script without the `.lua` extension specifying the substitutions to do,
refer to the default `anglofrench.lua` for an template;
* If input and/or output are not specified, standard input/output streams are assumed;

## Using the glue code

Include the header `azarify.h` in your C code and link with the source produced with `azarify -g`. The library
provides 2 functions for substituting the words in either a fixed-length buffer or inside a dynamically sized 
NULL-terminated string, which is reallocated in case the overall length is changed.

## What's about the name?

The prject was concieved as a way to demonstrate the phenomenon of Azarivka (Азарівка) to English speakers. 
[Nikolay Azarov][1] is an ex-PM of Ukraine who had trouble with the language and usually just naively transformed
the Russian words so that they seem Ukrainian, most notably changing vowels to «і» at unusual places, leading
to absolutely hilarious results to a person who is both a Russian and Ukrainian speaker. Kolya, please return
home. We miss you (No, we don't).

![Azarov](http://24daily.net/wp-content/uploads/2013/12/azarov22.jpg "Николай Азаров")

[1]: http://en.wikipedia.org/wiki/Mykola_Azarov
