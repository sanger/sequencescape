(function ($, undefined) {
    var taggers = $('select.tagchoice');

    $(document).ready(function() 
        { 
        $.tablesorter.defaults.widgets = ['zebra'];
        $.tablesorter.addParser({ 
            // set a unique id 
            id: 'assets', 
            is: function(s) { 
                // return false so this parser is not auto detected 
                return false; 
            }, 
            format: function(s) { 
                // replace asset ID and name with just ID
                return s.replace(/(\d+)\s(\w+)/i,"$1"); 
            }, 
            // set type, either numeric or text 
            type: 'numeric' 
        });
        $("#tag-assignment").tablesorter({
                headers: { 
                  3: { 
                    sorter:'assets' 
                  },
                  4: { 
                    sorter:'assets' 
                  }
                }
            });
        } 
    );
  
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
                    $(this).closest('tr').effect('highlight',3000);
                    chosenTagIndex++;
            });
        }
        highlightDuplicates();
    });
})(jQuery);
