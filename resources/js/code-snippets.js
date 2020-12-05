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

    function formatLineNumber(number) {
        var prefix = "";
        if (number < 10) {
            prefix = "&nbsp;&nbsp;&nbsp;";
        } else if (number < 100) {
            prefix = "&nbsp;&nbsp;";
        } else if (number < 1000) {
            prefix = "&nbsp;";
        }
        return prefix + number;
    }

    function fetchSnippet(el, url, line, weburl) {
        var weburl, requestUrl, oReq;

        requestUrl = url.replace(/github.com/, "raw.githubusercontent.com");
        requestUrl = requestUrl.replace(/(tree|blob)\//, "");

        oReq = new XMLHttpRequest();
        oReq.addEventListener("load", function() {
            var html, lines, start, deleteCount;

            html = '<p><a href="' + weburl + '" target="_blank" rel="noopener noreferrer">' + weburl + '</a></p>';
            lines = this.responseText.split(/\r\n|\n/);
            start = line - contextLines;
            if (start > 0) {
                lines.splice(0, start);
            }
            deleteCount = lines.length - (2 * contextLines) + 1;
            lines.splice(2 * contextLines - 1, deleteCount);
            
            lines.forEach(element => {
                start++;
                if (start == line) {
                    html += "<code class=\"highlight\">";
                } else {
                    html += "<code>";
                }
                html += formatLineNumber(start) + "&nbsp;" + element + "</code><br>";
            });
            el.innerHTML = html;
        });
        oReq.open("GET", requestUrl);
        oReq.send();

        el.innerHTML = "<tt>fetching...</tt>";
    }

    window.pmd_code_snippets = {
        fetch: fetchSnippet
    }
})();
