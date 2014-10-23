$(document).ready(function() {
	$(document).on('click',"a.event_remove",function (event){
	 	($(this).parent()).parent().remove();
	 	
	});	
});

function createTagSession() {

	if ($('#tag-question').val() == '') {
		$('#tag-question').focus();
		return;
	}

	var count = $('#taggers-table tbody tr').length;
	console.log(count)

	if (count < 1) {
		$('#tagger-name').focus();
		return;
	}

	var TAGGERS = {'tag_qid': 1,
					'tag_qst': $('#tag-question').val(),
					'key_options': {'y': 'YES', 'n': 'NO', 'm': 'Maybe'},
					'taggers': []
				}
	
	$('#taggers-table tbody tr').each(function(){
		TAGGERS['taggers'].push({'user_to_tag': $(this).children('.tname')[0].innerText, 'user_email': $(this).children('.temail')[0].innerText, 'number_to_tag': parseInt($(this).children('.tnum')[0].innerText)})
	});

	var sessionsData = {'sessionsObject' : JSON.stringify({'taggers_info': TAGGERS})}

	$.ajax({
		url: 'postSessions',
		type: 'POST',
		data: sessionsData,
		dataType: "json"
	}).success(function (data) {
		if (data.error) {
			$('#error-msg').html(data.error).style('background', 'aliceblue')
		}
		else {
			document.location.href = data
		}
	});
}

function addUser() {

	var textBox;

	$('#create-taggers .reqText').each(function(){
	    if ($(this).val() == '') {
	      // Get the current textBox
	      textBox = $(this)
	      // Exit loop we
	      return false;
	
	    }
	})

    if (!(validateEmail($('#tagger-email').val()))) {
        textBox = $('#tagger-email')
    }	

	// Check to see if this we have an empty textBox. 
	if (textBox) {
	  // Give focus to the empty textBox.
	  textBox.focus();
	  // document.getElementById(currentDiv+'Lbl').style.display='block'
	  return;
	}

	$('#taggers-table').append('<tr id="tagger_row"><td class ="edit-tagger tname">'+ $('#tagger-name').val() +'</td><td class ="edit-tag temail">' 
		+ $('#tagger-email').val() +'</td><td class ="edit-tag tnum">' + $('#number-to-tag').val() +'<a href="#" class="event_remove" >&times</a></td></tr>');	

	$('#create-taggers .reqText').each(function(){
		$(this).val('');
	});

	$('#tagger-name').focus();

}

// Code to Validate email address using jQuery - source jQuerybyexample.com '''
function validateEmail(sEmail) {
    var filter = /^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/;
    if (filter.test(sEmail)) {
        return true;
    }
    else {
        return false;
    }
}
