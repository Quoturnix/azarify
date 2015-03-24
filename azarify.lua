#!/usr/bin/env lua

-- Defaults
operation_mode='p'
verbosity='v'
freqfile=nil
infile=nil
outfile=nil
rulefile="anglofrench"
instream=io.stdin
outstream=io.stdout

-- Output code templates
codetempl_header=[[
/* THIS FILE IS GENERATED AUTOMATICALLY BY AZARIFY AND NOT INTENDED FOR MANUAL MODIFICATION
 * As a matter of fact, don't read it either, it will haunt you at night.
 * You have been warned.
 */
#include <string.h>
#include <stdlib.h>

]]

codetemp_footer=[[
/* TODO: only basic Latin and apostrophe supported so far */
static size_t lettertrans(char c)
{
    if (c=='\'')
        return 1;
    if (c>='A' && c<='Z')
        return (size_t)(c-'A');
    if (c>='a' && c<='z')
        return (size_t)(c-'a');
    return 0;
}

void azarify_process_buffer(char *buf, size_t n)
{
    char *out=malloc(n);
    
    memcpy(buf,out,n)
    free(out);
}

]]

-- Processing mode
function processing(instring)
    local words_number=0
    local words_replaced=0
    local words_stat={}
    
    return string.gsub(instring,
        "([A-Za-z']+)",
        function (w)
            -- Statistics
            if not words_stat[w] then
                words_stat[w] = 0 
            end
            words_stat[w] = words_stat[w] + 1
            words_number = words_number + 1
            
            -- Word substitution and stoplist
            for k,v in pairs(words) do
                if k==w then
                    if v~=w then -- Increment the counter if the word is not in stoplist
                        words_replaced = words_replaced + 1
                    end
                    return v
                end
            end

            -- Ending substitution
            for k,v in pairs(endings) do
                if k==string.sub(w, string.len(w)-string.len(k)+1,string.len(w)) then
                    words_replaced = words_replaced + 1
                    return string.sub(w, 1, string.len(w)-string.len(k))..v
                end
            end
    end), (words_replaced/words_number), words_stat
end

-- Generation mode
function generation()
end

-- Analyze params
-- TODO: various checks not to drop in Lua errors
dont_analyse={}
for i,v in ipairs(arg) do
    if not dont_analyse[i] then
        if v=='-p' or v=='-g' then 
            operation_mode=string.sub(v,2,2)
        elseif v=="-s" or v=="-q" or v=="-v" then
            verbosity=string.sub(v,2,2)
        elseif v=="-f" then
            dont_analyse[i+1]=true
            freqfile=arg[i+1]
        elseif v=="-o" then
            dont_analyse[i+1]=true
            outfile=arg[i+1]
        elseif v=="-i" then
            dont_analyse[i+1]=true
            infile=arg[i+1]
        elseif i==#arg then 
            rulefile=arg[i]
        end
    end
end

-- Building the uppercase version of the words filter
require(rulefile)
new_words={}
for k,v in pairs(words) do
    new_words[string.upper(string.sub(k,1,1))..string.sub(k,2,string.len(k))]=
        string.upper(string.sub(v,1,1))..string.sub(v,2,string.len(v))
    new_words[k]=v
end
words=new_words

-- Open streams
if infile then 
    instream=io.open(infile, 'r')
end

if outfile then
    outstream=io.open(outfile, 'w')
end

-- Do things
if operation_mode=='p' then
    local output, rate, stat = processing(instream:read("*all"))
    outstream:write(output)
    
    -- Print stats if we need
    if verbosity~="q" then
        io.stderr:write(verbosity=="s" and rate.."\n" or string.format("Substitution rate: %.3f%%\n", rate*100))
    end
    
    -- Record frequencies CSV if needed 
    if freqfile then
        fp=io.open(freqfile,"w")
        fp:write("word,frequency\n")
        for k,v in pairs(words_stat) do
            fp:write('"'..k..'",'..v.."\n")
        end
        fp:close()
    end
else
    outstream:write(codetempl_header..codetemp_footer)    
end

-- Close streams if necessary
if infile then
    infile:close()
end

if outfile then
    outfile:close()
end
