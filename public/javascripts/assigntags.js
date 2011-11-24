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
            var thisTagAssignments = duplicates[$(this).prop("selectedIndex")];
            if (thisTagAssignments.length >1)
            {
                for (var i=0, len = thisTagAssignments.size(); i<len; i++)
                {
                    var tableRow = $(taggers[thisTagAssignments[i]]).parent().parent();
                    tableRow.css("background", "#FFB0B0");
                }
            }
            else
            {
                $(taggers[thisTagAssignments[0]]).parent().parent().css("background", "white");
            }   
        });
    }
    
    $('select.tagchoice').change(function() {   
        if ($(this).siblings('input:checkbox').is(':checked'))
        {
            chosenTagIndex = $(this).prop("selectedIndex");
            // Set subsequent tags to increment from the chosen value
            remainingTaggers(taggers.index($(this))).each(function()
            {
                    $(this).prop("selectedIndex",chosenTagIndex+1);
					// A little animation to highlight the changed rows
                    $(this).parent().parent().animate({
                        backgroundColor: '#FFF3B0'
                    }, 2000).animate({
                        backgroundColor: '#ffffff'
                    }, 2000);
                    chosenTagIndex++;
            });
        }
        highlightDuplicates();
    });
})(jQuery);