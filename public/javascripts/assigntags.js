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
        var duplicatesPresent = false;
        taggers.each(function(index){
            var chosenTagIndex = $(this).prop("selectedIndex");
            if (duplicates[chosenTagIndex] == null)
            {
                duplicates[chosenTagIndex] = new Array();
                duplicates[chosenTagIndex].push(index);
            }
            else
                duplicates[chosenTagIndex].push(index);
            
        });
        taggers.each(function(index){
            var requestsAssigned = duplicates[$(this).prop("selectedIndex")];
            var quantityOfRequests = requestsAssigned.size();
            if (quantityOfRequests >1)
            {
                duplicatesPresent = true;
                for (var i=0; i<quantityOfRequests; i++)
                {
                    var tableRow = $(taggers[requestsAssigned[i]]).parent().parent();
                    tableRow.css("background", "#FFB0B0");
                }
            }
            else
            {
                $(taggers[requestsAssigned[0]]).parent().parent().css("background", "white");
            }   
        });
        if (duplicatesPresent)
            $('#stage_button').attr("disabled", true);
        else
            $('#stage_button').attr("disabled", false);
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
                    $(this).parent().parent().effect('highlight','3000');
                    chosenTagIndex++;
            });
        }
        highlightDuplicates();
    });
})(jQuery);