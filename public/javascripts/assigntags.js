(function($,undefined){
	var taggers = $('select.tagchoice');
 
	// This will return all the tag drop-downs after the current index
  	function remainingTaggers(currentIndex) {
	    return taggers.filter(function(index) {
	      return index > currentIndex;
	    });
	  }
  
	// This callback will indicate other rows using the same tag
	function highlightDuplicates() {
		var duplicates = {};
		taggers.each(function(index){
			var chosenTagIndex = $(this).prop("selectedIndex");
			if (duplicates[chosenTagIndex] != null)
				duplicates[chosenTagIndex].push(index);
			else
			{
				duplicates[chosenTagIndex] = new Array();
				duplicates[chosenTagIndex].push(index);
			}	
			
		});
		taggers.each(function(index){
			var chosenTagIndex = $(this).prop("selectedIndex");
			if (duplicates[chosenTagIndex].length >1)
			{
				console.log('duplicate tag: ', duplicates[chosenTagIndex])
				for (var i=0, len = duplicates[chosenTagIndex].size(); i<len; i++)
				{
					var thisTagger = taggers[duplicates[chosenTagIndex][i]];
					var tocolour = $(thisTagger).parent().parent();
					tocolour.css("background", "yellow");
				}
			}
			else
			{
				$(taggers[duplicates[chosenTagIndex][0]]).parent().parent().css("background", "white");
			}	
		});
	}
	
  	$('select').change(function() {
		taggerIndex = taggers.index($(this));
		chosenTagIndex = $(this).prop("selectedIndex");
	   	// Set remaining indices to increment from the chosen value
	   	remainingTaggers(taggerIndex).each(function(){$(this).prop("selectedIndex",chosenTagIndex+1);
		chosenTagIndex++;
		
	});
	highlightDuplicates();
	});
	
	// Convert array to object
	function oc(a)
	{
	  var o = {};
	  for(var i=0;i<a.length;i++)
	  {
	    o[a[i]]='';
	  }
	  return o;
	}
})(jQuery);