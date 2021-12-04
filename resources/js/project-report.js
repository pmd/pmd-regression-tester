/*
    This is what's included in project_diff_report.html
    to make the violation table work.

    It depends on the `project` global var, which is generated
    in another JS file by LiquidProjectRenderer
 */

$(document).ready(function () {

    function makeCodeLink(violation) {
        let template = project.source_link_template
        template = template.replace('{file}', project.file_index[violation.f])
        template = template.replace('{line}', violation.l);
        return template
    }

    function extractFilename(path) {
        const pathArray = path.split("/");
        return pathArray[pathArray.length - 1];
    }

    function renderCodeSnippet(violation) {
        var node = document.createElement('p');
        var url = project.source_link_base + '/' + project.file_index[violation.f];
        window.pmd_code_snippets.fetch(document, node, url, violation.l, makeCodeLink(violation));
        return node;
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

    var table = $('#violationsTable').DataTable({
        data: project.violations,
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
                    data = project.file_index[data]
                    // display only the file name (not full path), but use full
                    // path for sorting and such
                    if (type === "display") {
                        let line = 'ol' in row ? row.ol + " -> " + row.l : row.l;
                        //note : target='_blank' requires that the link open in a new tab
                        return "<a href='" + makeCodeLink(row) + "' target='_blank' rel='noopener noreferrer'>" + extractFilename(data) + " @ line " + line + "</a>"
                    } else if (type === "sort") {
                        return data + "#" + row.line
                    } else if (type === 'shortFile') {
                        return extractFilename(data)
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
        var tr = $(this).closest('tr');
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

});
