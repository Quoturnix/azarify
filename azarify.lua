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

-- Hashing parameters
-- TODO: seed the RNG
-- TODO: I hereby promise to study the theory 
-- and improve hashing function after 1st april
hash_p=524287 -- Mersenne prime 2^19-1
hash_a=math.random(0, hash_p-1)

-- Output code templates
codetempl_header=[[
/* THIS FILE IS GENERATED AUTOMATICALLY BY AZARIFY AND NOT INTENDED FOR MANUAL MODIFICATION
 * As a matter of fact, don't read it either, it will haunt you at night.
 * You have been warned.
 */
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>

]]

codetemp_footer=[[

static uint64_t azarify_hash_iteration(uint64_t h, char c)
{
    /* TODO: Mersenne prime fast modulo */
    return (h*azarify_hash_a + c) % azarify_hash_p;
}

static const char* azarify_hash_lookup_value(const char *needle, uint64_t hash, size_t start, size_t end, short ending)
{
    /* TODO: Maybe select the buckets size from Mersenne primes too? */
    unsigned i=hash % azarify_hash_buckets;
    
    while (azarify_hash_keys[i])
    {
        if (azarify_hash_flags[i] == ending && !strncmp(&needle[start], azarify_hash_keys[i], end-start))
            return azarify_hash_values[i];
        else
            i++;
    }
    
    return NULL;
}

/* TODO: expand the scope here and in Lua code to cover more than basic Latin */
#define azarify_is_alpha(c) (c=='\'' || ( c>='A' && c<='Z') || ( c>='a' && c<='z'))

/* TODO: this code is ABSOLUTELY messy, I'll fix all possible buffer size options when I wake up */
void azarify_process_buffer(char *buf, size_t n)
{
    char *buf_copy=malloc(n);
    size_t ianchor=0, oanchor=0, i, j;
    short matching=0;
    
    memcpy(buf_copy, buf, n);
    
    for (i=0; ; i++)
    {
        /* We're at the start of a new word, copy the interword chars and start matching */
        if (!matching && ( i==n || azarify_is_alpha(buf_copy[i])) )
        {
            if (i > ianchor)
                memcpy(&buf[oanchor], &buf_copy[ianchor], i-ianchor);
            oanchor+=i-ianchor;
            ianchor=i;
            matching=1;    
        } 
        /* We're at the end of a new word, find out if we have the word or the endings in our table */
        else if (matching && ( i == n || !azarify_is_alpha(buf_copy[i])))
        {
            const char *longest_match=NULL;
            size_t longest=0;
            uint64_t h;
            
            /* Iteratively calculate hash from the end of the word, looking each sequence up
             * until we end up with the whole word */
            for (j=0; j < i-ianchor; j++)
            {
                if (j==0) h=buf_copy[i-1];
                else h=azarify_hash_iteration(h, buf_copy[i-j-1]);
                
                const char *p=azarify_hash_lookup_value(buf_copy, h, i-j-1, i-1, i-j-1 != ianchor);
                if (p)
                {
                    longest_match=p;
                    longest=j+1;
                }
            }
            
            /* Check if we have any match, paste new word */
            if (longest_match)
            {
                /* Copy the first part of the word if needed */
                if (longest < i-ianchor)
                {
                    memcpy(&buf[oanchor], &buf_copy[ianchor], (i-ianchor)-longest);
                    oanchor+=(i-ianchor)-longest;
                }
                strcpy(&buf[oanchor], longest_match);
                oanchor+=strlen(longest_match);
            }
            /* Just copy the characters if not */
            else
            {
                /* TODO: Merge with above code */
                if (i > ianchor)
                    memcpy(&buf[oanchor], &buf_copy[ianchor], i-ianchor);
                oanchor+=i-ianchor;
            }
            ianchor=i;
            matching=0;
        }
        
        /* If the symbol was string's end, terminate process */
        if (!buf_copy[i] || i==n)
            break;
    }
    
    /* Make sure the string is zero-terminated */
    buf[oanchor]=0;
    
    free(buf_copy);
}

int main()
{
    char buf[4096] = "Hello, my name is John, I worked at GitHub";
    printf("Before:\t%s\n",buf);
    azarify_process_buffer(buf, 4096);
    printf("After:\t%s\n",buf);
}

]]

-- Sting hashing, the hash is calculated right-to-left. Because:
-- a. Allows to calculate the endings hash incrementally
-- b. Hebrew is written this way and Jews are smart
function strhash(str)
    local h=string.byte(string.sub(str, string.len(str), string.len(str)))
    for i=string.len(str)-1, 1, -1 do
        h = ((h*hash_a)+string.byte(string.sub(str,i,i))) % hash_p
    end
    return h
end

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

function tablelength(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

-- Generates a C hashtable from either of given tables
function generation()
    -- Setting up draft table
    local proto={}
    local hash_buckets=4*(tablelength(words)+tablelength(endings)) -- See https://xkcd.com/221/ for discussion "Why 4?"
    local keys=""
    local values=""
    local flags=""
    
    -- Calculating hashes, probing
    local function do_table(table)
        for k,v in pairs(table) do
            local h=strhash(k) % hash_buckets
            -- Linear probing atm
            while proto[h] do
                h = (h + 1) % hash_buckets            
            end
            proto[h]={ k, v, table==endings } -- Ultra black magic, don't do this in production
        end
    end
    do_table(words)
    do_table(endings)
    
    -- Final render into lists of strings/pointers
    for i=0,hash_buckets-1 do
        if proto[i] then 
            keys = keys .. '"'.. proto[i][1] .. '", '
            values = values .. '"'.. proto[i][2] .. '", '
            flags = flags .. (proto[i][3] and 1 or 0) .. ', '
        else
            keys = keys .. "NULL, "
            values = values .. "NULL, "
            flags = flags .. '0, '
        end
    end
    
    -- Spewing C
    return [[
static uint64_t azarify_hash_a = ]]..hash_a..[[;
static uint64_t azarify_hash_p = ]]..hash_p..[[;
static unsigned azarify_hash_buckets = ]]..hash_buckets..[[;
static const char* azarify_hash_keys[] = {
    ]]..keys..[[ 
};
static const char* azarify_hash_values[] = {
    ]]..values..[[ 
};
static short azarify_hash_flags[] = {
    ]]..flags..[[
};
]]
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
    outstream:write(codetempl_header..generation()..codetemp_footer)    
end

-- Close streams if necessary
if infile then
    instream:close()
end

if outfile then
    outstream:close()
end
