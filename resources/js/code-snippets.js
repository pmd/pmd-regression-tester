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
        let prefix = '';
        if (number < 10) {
            prefix = nbsp.repeat(3);
        } else if (number < 100) {
            prefix = nbsp.repeat(2);
        } else if (number < 1000) {
            prefix = nbsp;
        }
        return prefix + number;
    }

    function fetchSnippet(document, container, url, line, weburl) {
        var weburl, requestUrl, oReq;

        requestUrl = url.replace(/github.com/, "raw.githubusercontent.com");
        requestUrl = requestUrl.replace(/(tree|blob)\//, "");

        oReq = new XMLHttpRequest();
        oReq.addEventListener("load", function() {
            let lines, start, deleteCount;

            // we'll append stuff in the loop below
            container.innerHTML = '<p><a href="' + weburl + '" target="_blank" rel="noopener noreferrer">' + weburl + '</a></p>';

            lines = this.responseText.split(/\r\n|\n/);
            start = line - contextLines;
            if (start > 0) {
                lines.splice(0, start); // remove lines before
            }
            deleteCount = lines.length - (2 * contextLines) + 1;
            lines.splice(2 * contextLines - 1, deleteCount); // delete lines after

            // now we have just the lines which will be displayed
            lines.forEach(line => {
                start++;
                let lineElt = document.createElement("code");
                if (start === line) {
                    lineElt.classList.add("highlight");
                }
                // createTextNode escapes special chars
                lineElt.appendChild(document.createTextNode(formatLineNumber(start) + nbsp + line));
                lineElt.appendChild(document.createElement("br"));

                container.appendChild(lineElt); // append to the container
            });
        });
        oReq.open("GET", requestUrl);
        oReq.send();

        container.innerHTML = "<samp>fetching...</samp>";
    }

    window.pmd_code_snippets = {
        fetch: fetchSnippet
    }
})();
