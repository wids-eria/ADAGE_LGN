$(document).ready(function() {
	function CopyPrompt(textToCopy) {
		window.prompt("Press Cmd + C or Ctrl + C to copy.", textToCopy);
	}

	$("#secretClipboardButton").on('click', function (e) {
	    CopyPrompt($("#appSecretText").text().trim()); 
	});

	$("#tokenClipboardButton").on('click', function (e) {
	    CopyPrompt($("#appTokenText").text().trim()); 
	});
});

