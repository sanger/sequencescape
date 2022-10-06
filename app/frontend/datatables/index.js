// Load the datatables plugins
import $ from "jquery";
import "jszip";

// I went in a few circles here.
// Imports alone break styling when including rowReorder and responsive
// Switching to the requires and immediately executed factory functions
// resulted in the uncaught type-error mentioned in the link.
// https://datatables.net/forums/discussion/43042/uncaught-typeerror-cannot-set-property-of-undefined/p2

import dt from "datatables.net-bs4";
import dtButtons from "datatables.net-buttons-bs4";
import dtButtonsColVis from "datatables.net-buttons/js/buttons.colVis";
import dtButtonsHtml5 from "datatables.net-buttons/js/buttons.html5";
import dtFixedColumn from "datatables.net-fixedcolumns-bs4";
import dtFixedHeader from "datatables.net-fixedheader-bs4";
import dtResponsive from "datatables.net-responsive-bs4";
import dtRowGroup from "datatables.net-rowgroup-bs4";
import dtRowOrder from "datatables.net-rowreorder-bs4";

dt(window, $);
dtButtons(window, $);
dtButtonsColVis(window, $);
dtButtonsHtml5(window, $);
dtFixedColumn(window, $);
dtFixedHeader(window, $);
dtResponsive(window, $);
dtRowGroup(window, $);
dtRowOrder(window, $);

// We won't import the CSS automatically, so do it here.
// I couldn't import the non minified version here. While vite
// would appear to generate a valid request, the server would
// return a 404. From the returned error, it appeared that the
// CSS extension was stripped off when attempting to find the file on
// the file-system
import "datatables.net-bs4/css/dataTables.bootstrap4.min.css";
import "datatables.net-buttons-bs4/css/buttons.bootstrap4.min.css";
import "datatables.net-fixedheader-bs4/css/fixedHeader.bootstrap4.min.css";
import "datatables.net-responsive-bs4/css/responsive.bootstrap4.min.css";
import "datatables.net-rowreorder-bs4/css/rowReorder.bootstrap4.min.css";

// Load individual datatables implementations
import "./tableSortable";
import "./tableBatchEdit";
import "./tablePipelineInboxColumnSearch";
