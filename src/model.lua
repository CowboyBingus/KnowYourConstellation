local M = {}

function M.ascii(text)
    assert(type(text) == 'string' and not text:find('[^\32-\126]') and not text:find(';', 1, true),
        'Display text must be plain ASCII without semicolons')
    return text
end

function M.make(snapshot, catalogue)
    local cards = {}
    for _, tag in ipairs(snapshot.tags) do
        local entry = catalogue[tag]
        if entry then
            cards[#cards + 1] = {title=M.ascii(entry[1]), detail=M.ascii(entry[2])}
        end
    end
    if #cards == 0 then
        if snapshot.complete and #snapshot.tags==0 then
            cards[1] = {title='STANDARD FORCES', detail='No special constellation selected'}
        else
            cards[1] = {title='COMPOSITION UNAVAILABLE', detail='No resolved composition for this mission'}
        end
    end
    if snapshot.heavies and #snapshot.heavies > 0 then
        cards[#cards+1] = {title='HEAVY ENEMIES',
            detail=M.ascii(table.concat(snapshot.heavies,', '))}
    end
    local footer = 'Possible encounters. Spawns are not guaranteed.'
    if not snapshot.complete then footer = 'Base forecast. Special enemy intel is incomplete.' end
    if snapshot.difficulty < 6 then
        footer = snapshot.complete and 'Composition traits. Units vary with difficulty.' or footer
    end
    local parts = {}
    for _,card in ipairs(cards) do
        parts[#parts+1] = '['..card.title..'] '..card.detail
    end
    return {key=snapshot.key, screen=snapshot.screen,
        marquee=M.ascii(table.concat(parts,'    //    ')..'    /// END REPORT ///'),
        footer=footer, label='FORECAST // INTEL AND RECON', complete=snapshot.complete}
end

return M
