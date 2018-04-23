({
	getNotes : function(component) {
		var action = component.get('c.getNotes');
		action.setParams({
			incidentId: component.get('v.incidentId')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				var notes = response.getReturnValue();
				var recentNotes = [];
				var moreNotes = [];
				for (var i = 0; i < notes.length; i++) {
					if (i < 2) {
						recentNotes.push(notes[i]);
					} else {
						moreNotes.push(notes[i]);
					}
				}
				component.set('v.recentNotes', recentNotes);
				component.set('v.moreNotes', moreNotes);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	upsertNote: function(component, incidentNote) {
		var action = component.get('c.upsertAction');
		action.setParams({
			incidentAction: incidentNote
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				this.getNotes(component);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	},
	clearNote: function(component) {
		component.set('v.noteBody', null);
        component.set('v.isVisibleToCS', false);
	},
	clearEditNote: function(component) {
		component.set('v.editNoteId', null);
		component.set('v.editNoteBody', null);
	},
	deleteNote: function(component, noteId) {
		var action = component.get('c.deleteAction');
		action.setParams({
			actionId: noteId
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
				this.getNotes(component);
			} else if (state === 'ERROR') {
				// error handling goes here
			}
		});
		$A.enqueueAction(action);
	}
})