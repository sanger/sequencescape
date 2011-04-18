function select_requests_by_group(elementId,size,value) {
  for (var i = 1; i < size+1; i++) {
	$$('#' + elementId + '_' + i + ' input[type=checkbox]')[0].checked = value;

	element = $(elementId + '_' + i);   
	if (value) {
	  element.show();
	} else {
	  element.hide();
	}                   
  }                                            
}

function showElement(elementId, size) {     
  for (var i = 0; i < size+1; i++) {
	element = $(elementId + '_' + i);
      //console.debug(element);
      //console.debug(element.cells[0])
      if (element && element.style)
      {
        if (element.style.display == '')
          element.style.display = 'none';
         else
           element.style.display='';
      }
  }
}

function setFlagPriorityField(elementIdName, request_id)
{
  var element;
  var elementRequest;
  var elementReqName;

  elementReqName="setFlagPriority";

  if (document.all)
  {
    element = document.all[elementIdName];
    elementRequest =  document.all[elementReqName];
  }
  else
  {
    element = document.getElementById(elementIdName);
    elementRequest = document.getElementById(elementReqName);
  }

  elementRequest.value = request_id;
  element.value = parseInt(element.value) + 1;

}

function changeFlag(request_id)
{
    var answer = true;
    var element;
    var mycel;
    var myceltext;

    elementIdName = "flag_" + request_id;
    flag_value = "flag_value_" + request_id;
    if (document.all)
     {
      element = document.all[elementIdName];
      mycel = document.all[flag_value];
      }
    else
      {
        element = document.getElementById(elementIdName);
        mycel = document.getElementById(flag_value);
      }

    myceltext = mycel.childNodes.item(0);

    if (element.src.indexOf("icon_1_flag.png")>0)
      answer = confirm ("Are you sure you want to set this to normal priority ?")

    if (answer == true)
    {
       mycel.removeChild(myceltext);

       if (element.src.indexOf("icon_1_flag.png")>0)
        {
         element.src = "/images/icon_0_flag.png"
         var newtxt = document.createTextNode("0");
         mycel.appendChild(newtxt);
        }
       else
        {
         element.src = "/images/icon_1_flag.png"
         var newtxt = document.createTextNode("1");
         mycel.appendChild(newtxt);
        }

       //event on upFlag to call ruby script. 
       setFlagPriorityField("upFlag", request_id);
    }
}

function changeFlagMxLibraryChildren(item_id, size)
{
  var element;
  size=size+1
  for (var i=1;i<size;i++)
    {
      elementIdName = "flag_" +item_id+"_"+i;
      if (document.all)
        element = document.all[elementIdName];
      else if (document.getElementById)
        element = document.getElementById(elementIdName);
      
      if (element.src.indexOf("icon_1_flag.png")>0)
        element.src = "/images/icon_0_flag.png"
      else
        element.src = "/images/icon_1_flag.png"

    }
}

function changeFlagMxLibrary(request_id, item_id, size)
{
    var answer = true;
    var element;
    var mycel;
    var myceltext;

    elementIdName = "flag_" + item_id;
    flag_value = "flag_value_" + request_id;

    if (document.all)
     {
      element = document.all[elementIdName];
      mycel = document.all[flag_value];
      }
    else
      {
        element = document.getElementById(elementIdName);
        mycel = document.getElementById(flag_value);
      }

     myceltext = mycel.childNodes.item(0);
 
    if (element.src.indexOf("icon_1_flag.png")>0)
      answer = confirm ("Are you sure you want to set this to normal priority ?")

    if (answer == true)
    {
       mycel.removeChild(myceltext);
       if (element.src.indexOf("icon_1_flag.png")>0)
       {
         element.src = "/images/icon_0_flag.png"
         var newtxt = document.createTextNode("0");
         mycel.appendChild(newtxt);
       }
       else
       {
         element.src = "/images/icon_1_flag.png"
         var newtxt = document.createTextNode("1");
         mycel.appendChild(newtxt);
       }

      changeFlagMxLibraryChildren(item_id, size);

      //event on upFlag to call ruby script.
      setFlagPriorityField("upFlag", request_id);
    }

}