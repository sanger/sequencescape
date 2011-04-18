function pick_well(standard_id, plate, well)
{
	if($(plate+'_'+well).className == 'empty')
	{
		$(plate+'_'+well).removeClassName('empty');
	}
	else
	{
		$(plate+'_'+well).addClassName('empty');
	}


	if($$('.empty_well')[0].id)
	{
		free_well = $$('.empty_well')[0].id;
		box_content = Element.immediateDescendants($(plate+'_'+well))[0]
		$(free_well).update(box_content);
		$(free_well).removeClassName('empty_well');

	}
	else
	{
		alert('No more empty wells');
	}


}

function empty_well(well,row,col,plate_width)
{
	if($(well).className == 'empty')
	{
		$(well).removeClassName('empty');
		$(well).update(well);
	}
	else
	{
		$(well).addClassName('empty');
		$(well).update('Empty<input type="hidden" name="empty_well['+well+']" value="'+ (((row)*plate_width)+ col)+'">');
	}
}


function verifyplate(num_cols,num_rows,num_plates)
{
	var r=0;
	var p=0;
	var c=0;
	var returnvalues ="";
	for(p =0; p< num_plates; p++)
	{
		for(r = 0 ; r< num_rows; r++)
		{
			var col_length = $('plate['+p+']['+r+']').children.length;
			if((col_length-1) > num_cols)
			{
				alert('All rows must have '+num_cols+' wells ');
				return;
			}
			
			for(c =1; c<=num_cols; c++)
			{
				var plate_values =document.createElement("input");
				plate_values.setAttribute("type", "hidden");
				plate_values.setAttribute("name", 'plate['+p+']['+r+']['+(c-1)+']');
				if(c >= col_length )
				{
					plate_values.setAttribute("value", "");
				}
				else
				{
					plate_values.setAttribute("value", $('plate['+p+']['+r+']').children[c].id);
				}
				$('stage_form').appendChild(plate_values)
			}
		}
	}

	if (samples_are_selected() == true) {
    	$('stage_links').style.display = 'none';
    	$('stage_loading').style.display = 'inline';
    	document.getElementById('stage_form').submit();

  	} else {
    	alert('Please select one or more items.')
  	}
}
