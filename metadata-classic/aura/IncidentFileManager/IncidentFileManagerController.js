({
	onCometdLoaded : function(component, event, helper)
	{
      var cometd = new org.cometd.CometD();
      component.set('v.cometd', cometd);
      if (component.get('v.sessionId') != null)
        helper.connectCometd(component);
    },

	doInit : function(component, event, helper)
	{
		helper.getAttachments(component);

        //Platform event
        component.set('v.cometdSubscriptions', []);

        // Disconnect CometD when leaving page
        window.addEventListener('unload', function(event) {
            helper.disconnectCometd(component);
        });

        // Retrieve session id
        var action = component.get('c.getSessionId');

        action.setCallback(this, function(response) {
            if (component.isValid() && response.getState() === 'SUCCESS')
            {
                component.set('v.sessionId', response.getReturnValue());
                if (component.get('v.cometd') != null)
                {
                    helper.connectCometd(component);
                }
            }
            else
            {
              console.error(response);
            }
        });

        $A.enqueueAction(action);
	},

	saveFile: function(component, event, helper) {
		helper.save(component);
	},
	dragFile: function(component, event, helper) {
		event.dataTransfer.setData('text', event.currentTarget.dataset.attachmentId);
	},
	cancelModal: function(component, event, helper) {
		helper.cancelFileModal(component);
	},
	confirmDelete: function(component, event, helper) {
		helper.deleteFile(component);
	},
	confirmRename: function(component, event, helper) {
		helper.renameFile(component);
	},
	handleFileActionSelect: function(component, event, helper) {
		var value = event.getParam('value');
		if (!$A.util.isEmpty(value)) {
			if (value.indexOf('rename_') != -1) {
				var attachmentId = value.replace('rename_', '');
				component.set('v.tempAttachmentId', attachmentId);
				var attachments = component.get('v.attachments');
				var fileName;
				attachments.forEach(function(attachment) {
					if (attachmentId == attachment.fileId) {
						fileName = attachment.name;
					}
				});
				component.set('v.tempFileName', fileName);
				component.set('v.showFileNameModal', true);
			} else if (value.indexOf('delete_') != -1) {
				var attachmentId = value.replace('delete_', '');
				component.set('v.tempAttachmentId', attachmentId);
				component.set('v.showFileDeleteModal', true);
			}
		}
	},
	previewFile: function(component, event, helper) {
		event.preventDefault();
		var url = event.currentTarget.dataset.url;
		if (!$A.util.isEmpty(url)) {
			var appEvent = $A.get('e.c:CustomURLClicked');
			appEvent.setParams({
				url: url
			});
			appEvent.fire();
		}
	}
})