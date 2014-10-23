var TO_TAG =[]
var TAGGED_ITEMS = {}
var TAGGERS =[]
var SESSION_QST

$(document).ready(function() {
	keys =['y','n']
	loadItems();
	current = 0

	if (TO_TAG[0]) {
		loadToTag(current)	
	}
	
	$(document).on('keypress',function (event){

		key = String.fromCharCode(event.keyCode)
		if (!(TO_TAG[0])) {
			return;
		} 
  		else if (keys.indexOf(key) == -1) {
  			return;
  		}
  		else {appendPrevious(key, $('#tag_item')[0].dataset.comment_pos)}

  		current+=1
  		$('#tag_item').remove()
  		loadToTag(current)

	});

	$(document).on('click', "#tagged_row td.edit-tag", function(event) {
		$('#tag_item').remove()
		current-=1
		var to_edit = $(this).parent()[0].dataset.id
		$(this).parent().remove()
		loadToTag(to_edit)
	});

});

function loadItems() {
	var temp
	var url = '/view/' + $('#sessionid-text')[0].innerText
	// console.log(url)
	$.ajax({
		url: url,
		async: false,
		type: "GET"
	}).success(function (data) {
		console.log(data)
		// console.log(data.comments_to_tag.length)
		if (data.comments_to_tag) {
			// console.log(data)
			$('#session-user')[0].innerText = data.user_to_tag
			$('#session-tags')[0].innerText = data.comments_to_tag.length
			$('#tag-qst')[0].innerText = data.tag_qst

			SESSION_QST = data.tag_qst_id
			TO_TAG = data.comments_to_tag					
		}
		else if (data.error){
			$('#error-msg').html(data.error).style('background', 'aliceblue')
		}
		else {
			document.location.href = data
		}
	});			
}

function loadToTag(num) {
	$('#record').append('<tr id="tag_item" data-comment_pos="' + num + '"><td>' + TO_TAG[num].page_name +'</td><td>' + TO_TAG[num].post_message +'</td><td>' 
		+ TO_TAG[num].post_comments_message +'</td></tr>')

}

function appendPrevious(key, comment_pos) {
	var response;
	if (key=='y') { response = 'YES'}
	else { response = 'NO'}
	$('#previous-table').prepend('<tr id="tagged_row" data-id="' + comment_pos +  '"><td class ="edit-tag">'
		+ TO_TAG[comment_pos].page_name +'</td><td class ="edit-tag">' + TO_TAG[comment_pos].post_message +'</td><td class ="edit-tag">' 
		+ TO_TAG[comment_pos].post_comments_message +'</td><td class ="edit-tag">' + response+ '</td></tr>');
	TAGGED_ITEMS[TO_TAG[comment_pos].post_comments_id] = response

}

function saveLabels() {
	var count = 0
	$.each(TAGGED_ITEMS, function(index, value) {
    	count++;
	})
	if (count < 1) {
		$('#error-msg').html('You have not tagged any data!').style('background', 'aliceblue')
		return;
	}
	var saveItems = {'toSave' : JSON.stringify({'session_id' : $('#sessionid-text')[0].innerText, 'session_qst' : SESSION_QST, 'session_desc' : 'First Test session description', 'tagged_by': $('#session-user')[0].innerText, 'tag_pos': count, 'tags': TAGGED_ITEMS})}

	$.ajax({
		url: '/savelabels',
		async: false,
		type: 'POST',
		data: saveItems
	}).success(function (data) {
		document.location.href = data
	});
}

function addUser() {
	// $('#previous-table').prepend('<tr id="tagged_row" data-id="' + comment_pos +  '"><td class ="edit-tag">'
	// 	+ TO_TAG[comment_pos].page_name +'</td><td class ="edit-tag">' + TO_TAG[comment_pos].post_message +'</td><td class ="edit-tag">' 
	// 	+ TO_TAG[comment_pos].post_comments_message +'</td><td class ="edit-tag">' + response+ '</td></tr>');

	console.log('Tapinda v2')
}
