function fix_firefox_tooltip_layout()
{
	Element.setStyle($('property_sample_name'),"overflow:auto;");
}

function addNewInputColumn(element, row_number, name, class_name) {
  var column = document.createElement("td");
  column.setAttribute("class", class_name);

  var hidediv = document.createElement("div");
	hidediv.setAttribute("class", "cell_"+class_name);

  var input = document.createElement("input");
  input.setAttribute("type", "text");
  input.setAttribute("id", "samples_"+row_number+"_properties_"+name+"_value");
  input.setAttribute("name", "samples["+row_number+"][properties]["+name+"]");
  input.setAttribute("size", "30");
  input.setAttribute("value", "");

  // IE7 bug work around But now AN is visible.
  //if(name != "sample_ebi_accession_number")
  hidediv.appendChild(input);

  column.appendChild(hidediv);
  element.appendChild(column);
  return element;
}

function addNewTextAreaColumn(element, row_number, name, class_name) {
  var column = document.createElement("td");
  column.setAttribute("class", class_name);

  var hidediv = document.createElement("div");
	hidediv.setAttribute("class", "cell_"+class_name);

  var input = document.createElement("textarea");
  input.setAttribute("id", "samples_"+row_number+"_properties_"+name+"_value");
  input.setAttribute("name", "samples["+row_number+"][properties]["+name+"]");
  input.setAttribute("value", "");
  input.setAttribute("rows", "5");
  input.setAttribute("cols", "28");

  // IE7 bug work around. But now AN is visible.
  //if(name != "sample_ebi_accession_number")
  hidediv.appendChild(input);

  column.appendChild(hidediv);
  element.appendChild(column);
  return element;
}


function addNewSelectionColumn(element, row_number, name, class_name, options) {
  var column = document.createElement("td");
  column.setAttribute("class", class_name);

  var hidediv = document.createElement("div");
	hidediv.setAttribute("class", "cell_"+class_name);

  var input = document.createElement("select");
  input.setAttribute("id", "samples_"+row_number+"_properties_"+name+"_value");
  input.setAttribute("name", "samples["+row_number+"][properties]["+name+"]");
  options.each(function(opt) {
    var option = document.createElement("option");
    var text = document.createTextNode(opt)
    option.setAttribute("value", opt);
    option.appendChild(text);
    input.appendChild(option);
  });

	hidediv.appendChild(input)
  column.appendChild(hidediv);
  element.appendChild(column);

  return element;
}



function resetColumnVisibility(classname)
{
	var template_node = $$(classname)[0];
	var cell_styles = Element.getElementsBySelector(template_node,"div")
	var row_number = $$(classname).length;
	for(var r = 1; r< row_number; r++)
	{
		var new_row_details = $$(classname)[r];
		var new_row_styles = Element.getElementsBySelector(new_row_details,"div");
		for(var c = 0; c < cell_styles.length; c++)
		{
			if(Element.getStyle(cell_styles[c],"display") == "none")
			{
				Element.hide(new_row_styles[c]);
				new_row_styles[c].style.display = 'none';
			}
			else
			{
				Element.show(new_row_styles[c]);
				new_row_styles[c].style.display = '';
			}
		}
	}
}

function toggleGroupVisibility(group_name, visible)
{
	toggleCellVisibility('td', 'property_group_'+group_name, group_name, visible);
  toggleCellVisibility('th', 'property_group_'+group_name, group_name, visible);
  resetColumnVisibility("#samples_to_register tbody > tr");
}

function toggleCellVisibility(tag, classname, group_name,visible)
{
	var cells = $$(''+tag+' div.cell_'+classname+'');

	for(var i =0; i< cells.length; i++)
	{
		var td = cells[i];
		if (visible)
		{
			if(tag =="th")
			{
				//Element.appear(td);
				td.style.display = '';
			}
			else
			{
				td.style.display = '';
			}
		}
		else
		{
			if(tag =="th")
			{
				//Element.fold(td);
				td.style.display = 'none';
			}
			else
			{
				td.style.display = 'none';
			}
		}
	}

	var cells = $$(''+tag+' div.collapse_'+classname+'')
	for(var i =0; i< cells.length; i++)
	{
		var td = cells[i];
		if (visible)
		{
			//Element.fold(td);
			td.style.display = 'none';
		}
		else
		{
			if(i ==0)
			{
			  //Element.appear(td);
			  td.style.display = '';
		  }
		}
	}
}




