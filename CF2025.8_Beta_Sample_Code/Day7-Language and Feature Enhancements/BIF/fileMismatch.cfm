<cfscript>
    file1 = expandPath("./testfiles/server_log_backup.txt");
    file2 = expandPath("./testfiles/server_log_current.txt");

    writeOutput("<h1>FileMismatch() &mdash; Server Log Drift Detector</h1>");
    writeOutput("<p style='color:##555;'>Compares a <b>known-good backup</b> log against the <b>current</b> log to pinpoint exactly where they diverge.</p>");

    // ============================================
    // File metadata
    // ============================================
    info1 = getFileInfo(file1);
    info2 = getFileInfo(file2);

    writeOutput("<h2>File Overview</h2>");
    writeOutput("<table border='1' cellpadding='10' cellspacing='0' style='border-collapse:collapse; width:100%; max-width:800px;'>");
    writeOutput("<tr style='background:##e2e8f0;'><th></th><th>Backup (known-good)</th><th>Current</th></tr>");
    writeOutput("<tr><td><b>Path</b></td><td style='font-family:monospace;font-size:0.85em;'>#encodeForHTML(file1)#</td><td style='font-family:monospace;font-size:0.85em;'>#encodeForHTML(file2)#</td></tr>");
    writeOutput("<tr><td><b>Size</b></td><td>#numberFormat(info1.size)# bytes</td><td>#numberFormat(info2.size)# bytes</td></tr>");
    sizeDiff = info2.size - info1.size;
    diffLabel = sizeDiff == 0 ? "identical" : (sizeDiff > 0 ? "+" & numberFormat(sizeDiff) & " bytes" : numberFormat(sizeDiff) & " bytes");
    writeOutput("<tr><td><b>Size Difference</b></td><td colspan='2'>#diffLabel#</td></tr>");
    writeOutput("</table>");

    // ============================================
    // Run FileMismatch
    // ============================================
    start = getTickCount();
    pos = FileMismatch(file1, file2);
    elapsed = getTickCount() - start;

    writeOutput("<h2>FileMismatch Result</h2>");

    if (pos == -1) {
        writeOutput("<div style='border:3px solid ##38a169; border-radius:10px; padding:20px; margin:20px 0; background:##c6f6d5;'>");
        writeOutput("<h3 style='margin-top:0; color:##22543d;'>Files are identical &mdash; no drift detected</h3>");
        writeOutput("<p>The current log matches the backup byte-for-byte.</p>");
        writeOutput("<p style='color:##555;'>Comparison completed in #elapsed# ms</p>");
        writeOutput("</div>");
    } else {
        writeOutput("<div style='border:3px solid ##e53e3e; border-radius:10px; padding:20px; margin:20px 0; background:##fff5f5;'>");
        writeOutput("<h3 style='margin-top:0; color:##c53030;'>Drift detected at byte position #numberFormat(pos)#</h3>");
        writeOutput("<p style='color:##555;'>Comparison completed in #elapsed# ms</p>");

        // Read raw bytes around the mismatch for a hex-level view
        content1 = fileRead(file1);
        content2 = fileRead(file2);

        byte1 = mid(content1, pos + 1, 1);
        byte2 = mid(content2, pos + 1, 1);
        writeOutput("<table cellpadding='8' cellspacing='0' border='1' style='border-collapse:collapse; margin:12px 0;'>");
        writeOutput("<tr style='background:##e2e8f0;'><th></th><th>Backup</th><th>Current</th></tr>");
        writeOutput("<tr><td><b>Byte at position #pos#</b></td>");
        writeOutput("<td style='font-family:monospace; background:##c6f6d5;'><b>#encodeForHTML(byte1)#</b> (0x#formatBaseN(asc(byte1),16)#)</td>");
        writeOutput("<td style='font-family:monospace; background:##fed7d7;'><b>#encodeForHTML(byte2)#</b> (0x#formatBaseN(asc(byte2),16)#)</td>");
        writeOutput("</tr></table>");

        // Figure out which line the mismatch falls on
        textBefore = left(content1, pos);
        mismatchLine = listLen(textBefore, chr(10));

        writeOutput("<p><b>Mismatch falls on line #mismatchLine#</b> of the files.</p>");
        writeOutput("</div>");

        // ============================================
        // Side-by-side context around the mismatch
        // ============================================
        lines1 = listToArray(content1, chr(10));
        lines2 = listToArray(content2, chr(10));

        contextRadius = 3;
        startLine = max(1, mismatchLine - contextRadius);
        endLine = min(min(arrayLen(lines1), arrayLen(lines2)), mismatchLine + contextRadius);

        writeOutput("<h2>Side-by-Side Context (lines #startLine#&ndash;#endLine#)</h2>");
        writeOutput("<table border='1' cellpadding='8' cellspacing='0' style='border-collapse:collapse; width:100%; font-family:monospace; font-size:0.85em;'>");
        writeOutput("<tr style='background:##e2e8f0;'><th style='width:30px;'>##</th><th style='width:48%;'>Backup</th><th style='width:48%;'>Current</th><th>Match</th></tr>");

        for (i = startLine; i <= endLine; i++) {
            lineA = i <= arrayLen(lines1) ? lines1[i] : "";
            lineB = i <= arrayLen(lines2) ? lines2[i] : "";
            isMatch = (lineA == lineB);

            if (isMatch) {
                rowBg = "";
                matchIcon = "<span style='color:##38a169;font-size:1.2em;'></span>";
            } else {
                rowBg = " style='background:##fff5f5;'";
                matchIcon = "<span style='color:##e53e3e;font-size:1.2em;'></span>";
            }

            writeOutput("<tr#rowBg#>");
            writeOutput("<td style='text-align:center;color:##888;'>#i#</td>");

            if (!isMatch) {
                writeOutput("<td style='background:##c6f6d5;'>#encodeForHTML(lineA)#</td>");
                writeOutput("<td style='background:##fed7d7;'>#encodeForHTML(lineB)#</td>");
            } else {
                writeOutput("<td>#encodeForHTML(lineA)#</td>");
                writeOutput("<td>#encodeForHTML(lineB)#</td>");
            }
            writeOutput("<td style='text-align:center;'>#matchIcon#</td>");
            writeOutput("</tr>");
        }
        writeOutput("</table>");

        // ============================================
        // Full-file line-by-line diff summary
        // ============================================
        maxLines = max(arrayLen(lines1), arrayLen(lines2));
        diffCount = 0;
        diffLines = [];
        for (i = 1; i <= maxLines; i++) {
            la = i <= arrayLen(lines1) ? lines1[i] : "";
            lb = i <= arrayLen(lines2) ? lines2[i] : "";
            if (la != lb) {
                diffCount++;
                if (arrayLen(diffLines) < 20) {
                    arrayAppend(diffLines, i);
                }
            }
        }

        writeOutput("<h2>Full Diff Summary</h2>");
        writeOutput("<table border='1' cellpadding='10' cellspacing='0' style='border-collapse:collapse; max-width:600px;'>");
        writeOutput("<tr style='background:##e2e8f0;'><th>Metric</th><th>Value</th></tr>");
        writeOutput("<tr><td>Total lines (backup)</td><td>#arrayLen(lines1)#</td></tr>");
        writeOutput("<tr><td>Total lines (current)</td><td>#arrayLen(lines2)#</td></tr>");
        writeOutput("<tr><td>Lines that differ</td><td style='color:##e53e3e;font-weight:bold;'>#diffCount#</td></tr>");
        writeOutput("<tr><td>Lines that match</td><td style='color:##38a169;font-weight:bold;'>#maxLines - diffCount#</td></tr>");
        matchPct = maxLines > 0 ? ((maxLines - diffCount) / maxLines * 100) : 100;
        writeOutput("<tr><td>Match percentage</td><td><b>#numberFormat(matchPct, '99.9')#%</b></td></tr>");
        diffLineStr = arrayToList(diffLines, ", ");
        if (diffCount > 20) { diffLineStr &= " ..."; }
        writeOutput("<tr><td>Differing line numbers</td><td>" & diffLineStr & "</td></tr>");
        writeOutput("</table>");

        // ============================================
        // Detailed diff for each mismatched line
        // ============================================
        writeOutput("<h2>Detailed Differences</h2>");
        for (ln in diffLines) {
            la = ln <= arrayLen(lines1) ? lines1[ln] : "(line does not exist)";
            lb = ln <= arrayLen(lines2) ? lines2[ln] : "(line does not exist)";

            writeOutput("<div style='border-left:4px solid ##e53e3e; margin:12px 0; padding:10px 15px; background:##fff5f5; border-radius:0 6px 6px 0;'>");
            writeOutput("<b>Line #ln#</b>");
            writeOutput("<table cellpadding='4' style='margin-top:6px; font-family:monospace; font-size:0.85em; width:100%;'>");
            writeOutput("<tr><td style='color:##38a169; white-space:nowrap; vertical-align:top; width:60px;'><b>Backup:</b></td><td style='background:##c6f6d5; padding:6px; border-radius:4px;'>#encodeForHTML(la)#</td></tr>");
            writeOutput("<tr><td style='color:##e53e3e; white-space:nowrap; vertical-align:top;'><b>Current:</b></td><td style='background:##fed7d7; padding:6px; border-radius:4px;'>#encodeForHTML(lb)#</td></tr>");
            writeOutput("</table>");
            writeOutput("</div>");
        }
    }
</cfscript>
