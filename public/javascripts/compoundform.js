function showblock(lookuptable, selectionvalue)
{
	//find value in lookuptable
	var appear_id = "";

	for(x in lookuptable)
	{
		if(lookuptable[x][0] == "" || lookuptable[x][1] == null)
		{
		}
	  	else if(lookuptable[x][0].toLowerCase() == selectionvalue)
	  	{
			appear_id = lookuptable[x][1];
			document.getElementById(appear_id).style.display = '';
		}
		else if(lookuptable[x][1] != appear_id)
		{
			document.getElementById(lookuptable[x][1]).style.display = 'none';
		}
	}
	if(appear_id != "")
	{
		document.getElementById(appear_id ).style.display = '';
	}

}