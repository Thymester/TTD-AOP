TTDAOPUtils = {}

function TTDAOPUtils.Trim(value)
    if type(value) ~= 'string' then
        return ''
    end

    return (value:gsub('^%s*(.-)%s*$', '%1'))
end

function TTDAOPUtils.IsEmpty(value)
    return TTDAOPUtils.Trim(value) == ''
end

function TTDAOPUtils.ToLower(value)
    if type(value) ~= 'string' then
        return ''
    end

    return string.lower(value)
end

function TTDAOPUtils.ShallowCopyArray(items)
    local cloned = {}

    for index = 1, #items do
        cloned[index] = items[index]
    end

    return cloned
end

function TTDAOPUtils.ArrayContains(items, needle)
    for index = 1, #items do
        if items[index] == needle then
            return true
        end
    end

    return false
end

function TTDAOPUtils.ArrayRemoveValue(items, needle)
    for index = #items, 1, -1 do
        if items[index] == needle then
            table.remove(items, index)
        end
    end
end

function TTDAOPUtils.JoinServerIds(ids)
    if #ids == 0 then
        return ''
    end

    local formatted = {}
    for index = 1, #ids do
        formatted[index] = ('#%s'):format(ids[index])
    end

    return table.concat(formatted, ', ')
end

function TTDAOPUtils.GetFirstArg(args, fallback)
    if type(args) ~= 'table' or #args == 0 then
        return fallback
    end

    return args[1] or fallback
end

function TTDAOPUtils.MergeArgs(args, startIndex)
    if type(args) ~= 'table' then
        return ''
    end

    local startAt = startIndex or 1
    local parts = {}

    for index = startAt, #args do
        parts[#parts + 1] = args[index]
    end

    return TTDAOPUtils.Trim(table.concat(parts, ' '))
end

function TTDAOPUtils.CeilMinutesFromSeconds(seconds)
    if seconds <= 0 then
        return 0
    end

    return math.ceil(seconds / 60)
end

function TTDAOPUtils.IsValueInAliases(value, aliases)
    local lowered = TTDAOPUtils.ToLower(value)
    for index = 1, #aliases do
        if lowered == TTDAOPUtils.ToLower(aliases[index]) then
            return true
        end
    end

    return false
end
