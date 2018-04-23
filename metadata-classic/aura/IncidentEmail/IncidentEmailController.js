({
	handleDrop: function(component, event, helper) {
		event.stopPropagation();
        event.preventDefault();
        var dragZone = component.find('drop-zone');
		$A.util.removeClass(dragZone, 'drag-over');
        var attachmentId = event.dataTransfer.getData('text');
        var iframeWindow = component.find('email-publisher').getElement().contentWindow;
        iframeWindow.postMessage(attachmentId, '*');
	},

	allowDrop: function(component, event, helper) {
		event.preventDefault();
		var dragZone = component.find('drop-zone');
		$A.util.addClass(dragZone, 'drag-over');
	},

	handleDragLeave: function(component, event, helper) {
		var dragZone = component.find('drop-zone');
		$A.util.removeClass(dragZone, 'drag-over');
	}
})