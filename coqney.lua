#!/usr/bin/env lua

-- TODO: process param
require("anglofrench")

-- Building the uppercase version of the words filter
new_words={}
for k,v in pairs(words) do
    new_words[string.upper(string.sub(k,1,1))..string.sub(k,2,string.len(k))]=
        string.upper(string.sub(v,1,1))..string.sub(v,2,string.len(v))
    new_words[k]=v
end
words=new_words

-- Defaults
operation_mode='p'
verbosity='v'
freqfile=nil

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

-- Analyze params

-- Open streams

-- Do things
if operation_mode=='p' then
    local output, rate, stat = processing(io.read("*all"))
    io.write(output)
    
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
    
end
