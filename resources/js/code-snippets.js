/**
 * Simple module to fetch code snippets via ajax.
 * Only supports github hosted code repos.
 *
 * Usage:
 * var el = document.createElement('p');
 * var url = 'https://github.com/checkstyle/checkstyle/tree/checkstyle-8.0/src/it/resources/com/google/checkstyle/test/chapter4formatting/rule4822variabledistance/InputVariableDeclarationUsageDistanceCheck.java'
 * var line = 3;
 * var weburl = 'https://github.com/checkstyle/checkstyle/tree/checkstyle-8.0/src/it/resources/com/google/checkstyle/test/chapter4formatting/rule4822variabledistance/InputVariableDeclarationUsageDistanceCheck.java#L3'
 * window.pmd_code_snippets.fetch(el, url, line, weburl);
 */
(function() {
    const contextLines = 3;
    const nbsp = "\u00a0";

    // returns text, not html
    function formatLineNumber(number) {
        let prefix;
        if (number < 10) {
            prefix =  nbsp.repeat(3);
        } else if (number < 100) {
            prefix =  nbsp.repeat(2);
        } else if (number < 1000) {
            prefix = nbsp;
        }
        return prefix + number;
    }

    function fetchSnippet(document, container, url, violationLineNumber, weburl) {
        var weburl, requestUrl, oReq;

        requestUrl = url.replace(/github.com/, "raw.githubusercontent.com");
        requestUrl = requestUrl.replace(/(tree|blob)\//, "");

        oReq = new XMLHttpRequest();
        oReq.addEventListener("load", function() {
            let lines, start, deleteCount, lineSeparator;

            // we'll append stuff in the loop below
            container.innerHTML = '<p><a href="' + weburl + '" target="_blank" rel="noopener noreferrer">' + weburl + '</a></p>';

            if (this.responseText.indexOf('\r\n') >= 0) {
                lineSeparator = '\r\n';
            } else {
                lineSeparator = '\n';
            }
            lines = this.responseText.split(lineSeparator);
            start = violationLineNumber - contextLines;
            if (start > 0) {
                lines.splice(0, start); // remove lines before
            }
            deleteCount = lines.length - (2 * contextLines) + 1;
            lines.splice(2 * contextLines - 1, deleteCount); // delete lines after

            let table = document.createElement('table');
            table.classList.add('code-snippet');
            let tableBody = document.createElement('tbody');
            table.appendChild(tableBody);
            // now we have just the lines which will be displayed
            lines.forEach(line => {
                start++;
                let tableRow = document.createElement('tr');
                if (start === violationLineNumber) {
                    tableRow.classList.add("highlight");
                }

                let lineNumberColumn = document.createElement('td');
                lineNumberColumn.classList.add('line-number');
                tableRow.appendChild(lineNumberColumn);
                let lineNumberElement = document.createElement('code');
                lineNumberColumn.appendChild(lineNumberElement);
                lineNumberElement.setAttribute('data-line-number', formatLineNumber(start));

                let codeColumn = document.createElement('td');
                tableRow.appendChild(codeColumn);
                let codeElement = document.createElement("code");
                codeColumn.appendChild(codeElement);
                // createTextNode escapes special chars
                codeElement.appendChild(document.createTextNode(line));

                tableBody.appendChild(tableRow); // append row to the table
            });
            container.appendChild(table);

            if (navigator.clipboard) {
                let copyButton = document.createElement('button');
                copyButton.classList.add('btn-clipboard');
                copyButton.setAttribute('title', 'Copy to clipboard');
                copyButton.appendChild(document.createTextNode('copy'));
                copyButton.onclick = function() {
                    navigator.clipboard.writeText(lines.join(lineSeparator));
                }
                container.appendChild(copyButton);
            }
        });

        container.innerHTML = "<samp>fetching...</samp>";

        oReq.open("GET", requestUrl);
        oReq.send();
    }

    window.pmd_code_snippets = {
        fetch: fetchSnippet
    }
})();
