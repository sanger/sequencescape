(function ($, undefined) {
    var taggers = $('select.tagchoice');
  
    // This callback will indicate other rows using the same tag
    function highlightDuplicates() {
        var duplicates = {},
            duplicatesPresent = false;
        // Identify the duplicates:
        taggers.each(function (index) {
            var chosenTagIndex = $(this).prop("selectedIndex");
            if (duplicates[chosenTagIndex])
                duplicates[chosenTagIndex].push(index);
            else
                duplicates[chosenTagIndex] = [index];
        });
        // Highlight those rows which have duplicate tags
        taggers.each(function (index) {
            var requestsAssigned = duplicates[$(this).prop("selectedIndex")],
                quantityOfRequests = requestsAssigned.size();
            if (quantityOfRequests > 1)
            {
                duplicatesPresent = true;
                for (var i=0; i<quantityOfRequests; i++)
                {
                    $(taggers[requestsAssigned[i]]).closest('tr').addClass('duplicate-error');
                }
            }
            else
            {
                $(taggers[requestsAssigned[0]]).closest('tr').removeClass('duplicate-error');
            }   
        });
        if (duplicatesPresent)
            $('#stage_button').attr("disabled", true);
        else
            $('#stage_button').attr("disabled", false);
    }
    
    $('select.tagchoice').change(function () {   
        if ($('#increment-tags:checkbox').is(':checked'))
        {
            chosenTagIndex = $(this).prop("selectedIndex");
            // Set subsequent tags to increment from the chosen value
            taggers.slice(taggers.index($(this)) + 1).each(function () {
                    $(this).prop("selectedIndex",chosenTagIndex+1);
                    // A little animation to highlight the changed rows
                    $(this).parent().parent().effect('highlight',3000);
                    chosenTagIndex++;
            });
        }
        highlightDuplicates();
    });
})(jQuery);