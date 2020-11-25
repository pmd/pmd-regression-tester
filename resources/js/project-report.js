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

    $('#violationsTable').DataTable({
        data: project.violations,
        columns: [
            // other attributes:
            // l: line
            // ol: old line
            {"data": "f"}, // file
            {"data": "r"}, // rule
            {"data": "m"}, // message
            {"data": "t"}, // type
        ],
        deferRender: true,
        // scrollY: "6000px",
        dom: 'Pfrtip',
        searchPanes: {
            viewTotal: true,
            cascadePanes: true,
            columns: [0, 1, 3],
            order: ['Rule', 'Location', 'Type']
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
        rowCallback(row, data, index) {
            $(row).addClass(cssClass[data.t]);
        },
    });

});
