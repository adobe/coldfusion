component {
    public array function chunkDirectory(required string docsDir) {
        var items = [];
        if (!directoryExists(arguments.docsDir)) {
            return items;
        }

        var fileNames = directoryList(arguments.docsDir, false, "name");
        arraySort(fileNames, "textnocase");

        for (var fileName in fileNames) {
            var extension = lcase(listLast(fileName, "."));
            if (!listFindNoCase("md,txt", extension)) {
                continue;
            }

            var filePath = arguments.docsDir & application.pathSep & fileName;
            var fileChunks = chunkFile(filePath, fileName);
            arrayAppend(items, fileChunks, true);
        }

        return items;
    }

    public array function chunkFile(required string filePath, required string sourceName) {
        var rawText = fileRead(arguments.filePath, "utf-8");
        var normalizedText = replace(rawText, chr(13) & chr(10), chr(10), "all");
        normalizedText = replace(normalizedText, chr(13), chr(10), "all");

        var defaultStepIds = extractStepIds(normalizedText);
        var sections = splitSections(normalizedText);
        var items = [];
        var chunkIndex = 0;

        for (var section in sections) {
            var sectionText = trim(section.text);
            if (!len(sectionText)) {
                continue;
            }

            chunkIndex++;
            var stepIds = arrayLen(section.stepIds) ? section.stepIds : defaultStepIds;
            if (!arrayLen(stepIds)) {
                stepIds = ["all"];
            }

            arrayAppend(items, {
                id: rereplace(arguments.sourceName, "[^A-Za-z0-9]", "-", "all") & "-" & chunkIndex,
                text: sectionText,
                metadata: {
                    source: arguments.sourceName,
                    section: section.title,
                    chunkIndex: chunkIndex,
                    stepIds: arrayToList(stepIds, ",")
                }
            });
        }

        return items;
    }

    private array function extractStepIds(required string text) {
        var match = reFind("(?i)stepIds:\s*([^\r\n<]+)", arguments.text, 1, true);
        if (!match.len[1] || match.len[2] <= 0) {
            return [];
        }
        var raw = trim(mid(arguments.text, match.pos[2], match.len[2]));
        raw = rereplace(raw, "\s*-->\s*$", "", "all");
        return listToArray(raw, ",");
    }

    private array function splitSections(required string text) {
        var lines = listToArray(arguments.text, chr(10), true);
        var sections = [];
        var currentTitle = "Overview";
        var currentLines = [];
        var currentStepIds = [];

        for (var line in lines) {
            var trimmedLine = trim(line);

            if (reFind("(?i)^<!--\s*stepIds:", trimmedLine)) {
                var typeList = reReplace(trimmedLine, "(?i)^<!--\s*stepIds:\s*|\s*-->$", "", "all");
                currentStepIds = listToArray(typeList, ",");
                continue;
            }

            if (isMarkdownHeading(trimmedLine)) {
                if (arrayLen(currentLines)) {
                    arrayAppend(sections, {
                        title: currentTitle,
                        text: arrayToList(currentLines, chr(10)),
                        stepIds: duplicate(currentStepIds)
                    });
                }
                currentTitle = trim(removeMarkdownHeadingPrefix(trimmedLine));
                currentLines = [trimmedLine];
                currentStepIds = [];
                continue;
            }

            arrayAppend(currentLines, line);
        }

        if (arrayLen(currentLines)) {
            arrayAppend(sections, {
                title: currentTitle,
                text: arrayToList(currentLines, chr(10)),
                stepIds: duplicate(currentStepIds)
            });
        }

        if (!arrayLen(sections)) {
            arrayAppend(sections, {
                title: "Document",
                text: arguments.text,
                stepIds: []
            });
        }

        return sections;
    }

    private boolean function isMarkdownHeading(required string line) {
        if (!len(arguments.line) || left(arguments.line, 1) != chr(35)) {
            return false;
        }
        return reFind("^\x23{1,3}\s+\S", arguments.line) > 0;
    }

    private string function removeMarkdownHeadingPrefix(required string line) {
        return reReplace(arguments.line, "^\x23{1,3}\s+", "");
    }
}
