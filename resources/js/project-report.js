/*
    This is what's included in project_diff_report.html, project_pmd_report.html and project_cpd_report.html
    to make the violation table and duplication table work.

    It depends on the `pmd_report` and `cpd_report` global vars, which is generated
    in another JS file by LiquidProjectRenderer
 */

$(document).ready(function () {

    function extractFilename(path) {
        const pathArray = path.split("/");
        return pathArray[pathArray.length - 1];
    }

    const cssClass = {
        "+": "added",
        "-": "removed",
        "~": "changed",
    }

    const typeDisplay = {
        "+": "Added",
        "-": "Removed",
        "~": "Changed",
    }

    function renderViolationsTable() {
        function makeCodeLink(violation) {
            let template = pmd_report.source_link_template
            template = template.replace('{file}', pmd_report.file_index[violation.f])
            template = template.replace('{line}', violation.l);
            return template
        }
        function renderCodeSnippet(violation) {
            var node = document.createElement('p');
            var url = pmd_report.source_link_base + '/' + pmd_report.file_index[violation.f];
            window.pmd_code_snippets.fetch(document, node, url, violation.l, makeCodeLink(violation));
            return node;
        }

        var table = $('#violationsTable').DataTable({
            data: pmd_report.violations,
            columns: [
                // other attributes in data:
                // l: line
                // ol: old line
                {"data": "f"}, // file
                {"data": "r"}, // rule
                {"data": "m"}, // message
                {"data": "t"}, // type
            ],
            deferRender: true,
            // scrollY: "6000px",
            dom: 'Pfrtipl', // Search Panes, filtering input, processing display element, table, table information summary, pagination control, length changing input control
            searchPanes: {
                viewTotal: true,
                cascadePanes: true,
                columns: [0, 1, 3],
                order: ['Rule', 'Location (click row to expand)', 'Type'],
                threshold: 1 // always show filters in search pane (default: 0.6)
            },
            // scrollCollapse: true,
            // paging: false,
            columnDefs: [
                { //file column
                    render(data, type, row) {
                        data = pmd_report.file_index[data];
                        // display only the file name (not full path), but use full
                        // path for sorting and such
                        if (type === "display") {
                            let line = 'ol' in row ? row.ol + "→" + row.lo : row.lo;
                            //note : target='_blank' requires that the link open in a new tab
                            return "<a href='" + makeCodeLink(row) + "' target='_blank' rel='noopener noreferrer'>" + extractFilename(data) + " @ line " + line + "</a>";
                        } else if (type === "sort") {
                            return data + "#" + row.l;
                        } else if (type === 'shortFile') {
                            return extractFilename(data);
                        } else {
                            return data;
                        }
                    },
                    searchPanes :{
                        orthogonal: {
                            'display': 'shortFile',
                            'search':  undefined
                        }
                    },
                    targets: 0
                },
                { // rule column
                    render(data, type, row) {
                        // display only the file name (not full path), but use full
                        // path for sorting and such
                        if (type === "display")
                            return "<a href='#rule-summary-" + data + "'>" + data + "</a>"
                        else
                            return data;
                    },
                    searchPanes: {
                        orthogonal: {
                            'display' : 'sort' // do not use the display, which is an <a>
                        }
                    },
                    targets: 1
                },
                { // type column
                    visible: false,
                    render(data, type, row) {
                        return type ==='display' ? typeDisplay[data] : cssClass[data]
                    },
                    targets: 3
                },
            ],
            displayLength: 25,
            lengthMenu: [ [10, 20, 25, 50, 100, -1], [10, 20, 25, 50, 100, "All"] ],
            rowCallback(row, data, index) {
                $(row).addClass(cssClass[data.t]);
            },
        });

        $('#violationsTable tbody').on('click', 'tr', function() {
            // the event handler might be executed on "tr" elements in sub tables, such as
            // code snippets or it might be a child-row (a tr, whose previous sibling has class dt-hasChild)
            if (this.parentElement.parentElement.id  !== 'violationsTable') {
                return;
            }
            if (this.previousElementSibling !== null && this.previousElementSibling.classList.contains('dt-hasChild')) {
                return;
            }

            var tr = $(this);
            var row = table.row( tr );

            if ( row.child.isShown() ) {
                // This row is already open - close it
                row.child.hide();
                tr.removeClass('shown');
            }
            else {
                // Open this row
                row.child( renderCodeSnippet(row.data()) ).show();
                tr.addClass('shown');
            }
        });
    }

    function renderDuplicationTable() {
        const COLUMN_LOCATION = 0;
        const COLUMN_LOCATION_FILE = 0; // in the location array: file index
        const COLUMN_LOCATION_BEGIN_LINE = 1; // in the location array
        const COLUMN_LOCATION_END_LINE = 2; // in the location array
        const COLUMN_LOCATION_STRING = 3; // in the location array
        const COLUMN_LINES = 1;
        const COLUMN_TOKENS = 2;
        const COLUMN_CODEFRAGMENT = 3; // codefragment
        const COLUMN_TYPE = 4; // type (+, -, ~)

        function makeCodeLinkDuplication(firstDuplication) {
            let template = cpd_report.source_link_template;
            template = template.replace('{file}', cpd_report.file_index[firstDuplication[COLUMN_LOCATION_FILE]]);
            template = template.replace('{line}', `${firstDuplication[COLUMN_LOCATION_BEGIN_LINE]}-L${firstDuplication[COLUMN_LOCATION_END_LINE]}`);
            return template;
        }
        function renderCodeFragment(data) {
            var node = document.createElement('p');
            var innerHTML = `${data[COLUMN_LOCATION].length} locations:<br>`;
            data[COLUMN_LOCATION].forEach(location => {
                let url = makeCodeLinkDuplication(location);
                innerHTML += `<a href="${url}" target="_blank" rel="noopener noreferrer">${url} @ line ${location[COLUMN_LOCATION_STRING]}</a><br>`;
            });
            innerHTML += `code fragment (lines: ${data[COLUMN_LINES]}, tokens: ${data[COLUMN_TOKENS]}):<br>`;

            let table = document.createElement('table');
            table.classList.add('code-snippet');
            let tableBody = document.createElement('tbody');
            table.appendChild(tableBody);
            // line number of first location
            let lineNumber = data[COLUMN_LOCATION][0][COLUMN_LOCATION_BEGIN_LINE];
            data[COLUMN_CODEFRAGMENT].split('\n').forEach(line => {
                let tableRow = document.createElement('tr');
                let lineNumberColumn = document.createElement('td');
                lineNumberColumn.classList.add('line-number');
                tableRow.appendChild(lineNumberColumn);
                let lineNumberElement = document.createElement('code');
                lineNumberColumn.appendChild(lineNumberElement);
                lineNumberElement.setAttribute('data-line-number', lineNumber);

                let codeColumn = document.createElement('td');
                tableRow.appendChild(codeColumn);
                let codeElement = document.createElement("code");
                codeColumn.appendChild(codeElement);
                // createTextNode escapes special chars
                codeElement.appendChild(document.createTextNode(line));

                tableBody.appendChild(tableRow); // append row to the table
                lineNumber++; // increment line number for each line
            });

            node.innerHTML = innerHTML + table.outerHTML;
            return node;
        }

        var cpdTable = $('#duplicationsTable').DataTable({
            data: cpd_report.duplications,
            columns: [
                {"data": COLUMN_LOCATION},
                {"data": COLUMN_LINES},
                {"data": COLUMN_TOKENS},
                {"data": COLUMN_CODEFRAGMENT},
                {"data": COLUMN_TYPE},
            ],
            deferRender: true,
            dom: 'Pfrtipl', // Search Panes, filtering input, processing display element, table, table information summary, pagination control, length changing input control
            searchPanes: {
                viewTotal: true,
                cascadePanes: true,
                columns: [0, 4],
                order: ['Location (click row to expand)', 'Type'],
                threshold: 1 // always show filters in search pane (default: 0.6)
            },
            columnDefs: [
                { // locations column
                    render(data, type, row) {
                        let first = data[0];
                        let firstPath = cpd_report.file_index[first[COLUMN_LOCATION_FILE]];
                        let firstLocation = first[COLUMN_LOCATION_STRING];
                        let firstFilename = extractFilename(firstPath);
                        if (type === "display") {
                            return "<a href='" + makeCodeLinkDuplication(first) + "' target='_blank' rel='noopener noreferrer'>" + firstFilename + " @ line " + firstLocation + "</a>" + (data.length > 1 ? " (and " + (data.length - 1) + " more)" : "");
                        } else if (type === "sort") {
                            return firstPath + "#" + first[COLUMN_LOCATION_END_LINE];
                        } else if (type === 'filter') {
                            return firstFilename;
                        } else if (type === 'shortFile') {
                            return firstFilename;
                        } else {
                            return data;
                        }
                    },
                    searchPanes :{
                        orthogonal: {
                            'display': 'shortFile',
                            'search':  undefined
                        }
                    },
                    targets: 0
                },
                { // codefragment column
                    render(data, type, row) {
                        if (type === "display") {
                            data = data.replace(/\r\n|\n/g, "\\n"); // replace newlines with \n for better display in the table
                            return data.length > 50 ? data.substring(0, 50) + "..." : data;
                        }
                        return data;
                    },
                    targets: 3
                },
                { // type column
                    visible: false,
                    render(data, type, row) {
                        return type ==='display' ? typeDisplay[data] : cssClass[data]
                    },
                    targets: 4
                },
            ],
            displayLength: 25,
            lengthMenu: [ [10, 20, 25, 50, 100, -1], [10, 20, 25, 50, 100, "All"] ],
            rowCallback(row, data, index) {
                $(row).addClass(cssClass[data[4]]);
            },
        });
        $('#duplicationsTable tbody').on('click', 'tr', function() {
            // the event handler might be executed on "tr" elements in sub tables, such as
            // a child-row (a tr, whose previous sibling has class dt-hasChild)
            if (this.parentElement.parentElement.id  !== 'duplicationsTable') {
                return;
            }
            if (this.previousElementSibling !== null && this.previousElementSibling.classList.contains('dt-hasChild')) {
                return;
            }

            var tr = $(this);
            var row = cpdTable.row( tr );

            if ( row.child.isShown() ) {
                // This row is already open - close it
                row.child.hide();
                tr.removeClass('shown');
            }
            else {
                // Open this row
                row.child( renderCodeFragment(row.data()) ).show();
                tr.addClass('shown');
            }
        });
    }

    if ($('#violationsTable').length > 0) {
        renderViolationsTable();
    }
    if ($('#duplicationsTable').length > 0) {
        renderDuplicationTable();
    }

});
