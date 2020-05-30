-- Get table keys and delimit them.
-- {hello = true, world = true} with delimeter ', ' becomes "hello, world"
function concatSet(set, delimiter)
    str = ''
    for k, v in pairs(set) do
        str = str .. k .. delimiter
    end
    str = string.sub(str, 0, #str - #delimiter)
    return str
end

