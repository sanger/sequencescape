import $ from "jquery";

// Load the datatables plugins
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

// Load individual datatables implementations
import "./tableSortable";
import "./tableBatchEdit";
import "./tablePipelineInboxColumnSearch";

// Load the datatables bootstrap 4 styling
import "datatables.net-bs4/css/dataTables.bootstrap4.min.css";
import "datatables.net-buttons-bs4/css/buttons.bootstrap4.min.css";
import "datatables.net-fixedheader-bs4/css/fixedHeader.bootstrap4.min.css";
import "datatables.net-responsive-bs4/css/responsive.bootstrap4.min.css";
import "datatables.net-rowreorder-bs4/css/rowReorder.bootstrap4.min.css";
