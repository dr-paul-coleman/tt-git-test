({
	getAttachments : function(component) {
	    var incidentId = component.get('v.incidentId');
		var action = component.get('c.getAllAttachments');
		action.setParams({
			'incidentId': incidentId
		});

		console.log('getAttachments: ' + incidentId);

		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var attachments = response.getReturnValue();
				component.set('v.attachments', attachments);
				console.log(attachments);
				console.log(JSON.stringify(attachments));
			} else if (state === 'ERROR') {
				// error handling goes here
				console.log('getAttachments Error');
			}
		});

        $A.enqueueAction(action);
	},
	MAX_FILE_SIZE: 4500000, /* 6 000 000 * 3/4 to account for base64 */
	CHUNK_SIZE: 904000, /* Use a multiple of 4 */
	save : function(component) {
		component.set('v.showSpinner', true);
		var fileInput = component.find("file").getElement();
		var file = fileInput.files[0];
   
		if (file.size > this.MAX_FILE_SIZE) {
			alert('File size cannot exceed ' + this.MAX_FILE_SIZE + ' bytes.\n' +
			  'Selected file size: ' + file.size);
			return;
		}
		
		var fr = new FileReader();

		var self = this;
		fr.onload = $A.getCallback(function() {
			var fileContents = fr.result;
			var base64Mark = 'base64,';
			var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;

			fileContents = fileContents.substring(dataStart);
		
			self.upload(component, file, fileContents);
		});

		fr.readAsDataURL(file);
	},
	upload: function(component, file, fileContents) {
		var fromPos = 0;
		var toPos = Math.min(fileContents.length, fromPos + this.CHUNK_SIZE);
		
		// start with the initial chunk
		this.uploadChunk(component, file, fileContents, fromPos, toPos, '');   
	},
	uploadChunk : function(component, file, fileContents, fromPos, toPos, attachId) {
		var action = component.get("c.saveTheChunk"); 
		var chunk = fileContents.substring(fromPos, toPos);

		action.setParams({
			parentId: component.get("v.incidentId"),
			fileName: file.name,
			base64Data: encodeURIComponent(chunk), 
			contentType: file.type,
			fileId: attachId
		});
	   
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				attachId = response.getReturnValue();
				fromPos = toPos;
				component.set('v.uploadPercentage', fromPos / fileContents.length * 100);
				toPos = Math.min(fileContents.length, fromPos + this.CHUNK_SIZE);    
				if (fromPos < toPos) {
					this.uploadChunk(component, file, fileContents, fromPos, toPos, attachId);  
				} else {
					this.getAttachments(component);
				}
				this.animateProgress(component);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action); 
	},
	animateProgress: function(component) {
		var uploadPercentage = component.get('v.uploadPercentage');
		var progressBar = component.find('progress-bar').getElement();
		$(progressBar).animate({
			width: uploadPercentage + '%'
		}, 400, $A.getCallback(function() {
			if (uploadPercentage >= 100) {
				component.set('v.showSpinner', false);
				component.set('v.uploadPercentage', 0);
				var fileInput = component.find("file").getElement();
				fileInput.value = null;
			}
		}));
	},
	editFileName: function(component) {
		component.set('v.showFileNameModal', true);
	},
	renameFile: function(component) {
		var attachmentId = component.get('v.tempAttachmentId');
		var name = component.get('v.tempFileName');
		var action = component.get('c.renameFile');
		action.setParams({
			attachmentId: attachmentId,
			name: name
		});
        
        console.log('attachmentId: ' + attachmentId);
        
		action.setCallback(this, function(response) { 
			var state = response.getState();
			if (state === 'SUCCESS') {
				this.getAttachments(component);
				this.cancelFileModal(component);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	deleteFile: function(component) {
		var attachmentId = component.get('v.tempAttachmentId');
		var action = component.get('c.deleteFile');
		action.setParams({
			attachmentId: attachmentId
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				this.getAttachments(component);
				this.cancelFileModal(component);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	cancelFileModal: function(component) {
		component.set('v.tempFileName', null);
		component.set('v.tempAttachmentId', null);
		component.set('v.showFileNameModal', false);
		component.set('v.showFileDeleteModal', false);
	},

	connectCometd : function(component)
	{
	    var helper = this;

        // Configure CometD
        var cometdUrl = window.location.protocol+'//'+window.location.hostname+'/cometd/40.0/';
        var cometd = component.get('v.cometd');

        cometd.configure({
            url: cometdUrl,
            requestHeaders: { Authorization: 'OAuth '+ component.get('v.sessionId')},
            appendMessageTypeToURL : false
        });

        cometd.websocketEnabled = false;

        // Establish CometD connection
        console.log('Connecting to CometD: '+ cometdUrl);
        cometd.handshake(function(handshakeReply){

            if (handshakeReply.successful)
            {
                console.log('Connected to CometD.');

                // Subscribe to platform event
                var newSubscription = cometd.subscribe('/event/AttachmentEvent__e',function(platformEvent) {
                    console.log('Platform event received: '+ JSON.stringify(platformEvent));

                    var loadAttachments = $A.getCallback(function() {
                                                   if (component.isValid())
                                                   {
                                                        console.log('Load Attachments');
                                                        helper.onReceiveNotification(component, platformEvent);
                                                    }});
                    loadAttachments();

                });

                // Save subscription for later
                var subscriptions = component.get('v.cometdSubscriptions');
                subscriptions.push(newSubscription);
                component.set('v.cometdSubscriptions', subscriptions);
            }
            else
            {
                console.error('Failed to connected to CometD.');
            }
        });
    },

    disconnectCometd : function(component)
    {
        var cometd = component.get('v.cometd');

        // Unsuscribe all CometD subscriptions
        cometd.batch(function() {

            var subscriptions = component.get('v.cometdSubscriptions');
            subscriptions.forEach(function (subscription) {
                cometd.unsubscribe(subscription);
            });
        });

        component.set('v.cometdSubscriptions', []);

        // Disconnect CometD
        cometd.disconnect();
        console.log('CometD disconnected.');
    },

    onReceiveNotification : function(component, platformEvent)
    {
        var helper = this;

        console.log('Received notification');


        helper.getAttachments(component);
    },



})