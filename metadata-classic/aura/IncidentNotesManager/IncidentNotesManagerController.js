({
	doInit : function(component, event, helper) {
		helper.getNotes(component);
	},
	addNote: function(component, event, helper) {
		var incidentNote = {
			Notes__c: component.get('v.noteBody'),
			MIIncident__c: component.get('v.incidentId'),
            IsVisibleToCS__c: component.get('v.isVisibleToCS'),
			Name: 'Specialist note',
			Status__c: 'Completed',
			Type__c: 'Note',
			sobjectType: 'MIIncidentAction__c'
		};
		helper.upsertNote(component, incidentNote);
		helper.clearNote(component);
	},
	toggleMoreNotes: function(component, event, helper) {
		component.set('v.showMoreNotes', !component.get('v.showMoreNotes'));
		var moreNotesElem = component.find('moreNotes').getElement();
		$(moreNotesElem).slideToggle();
	},
	removeNote: function(component, event, helper) {
		var noteId = event.currentTarget.dataset.noteId;
		helper.deleteNote(component, noteId);
	},
	editNote: function(component, event, helper) {
		var editNoteId = event.currentTarget.dataset.noteId;
		component.set('v.editNoteId', editNoteId);
		var editNoteBody;
        var editIsVisibleToCS = false;
		var recentNotes = component.get('v.recentNotes');
		recentNotes.forEach(function(note) {
			if (note.record.Id == editNoteId) {
				editNoteBody = note.record.Notes__c;
                editIsVisibleToCS = note.record.IsVisibleToCS__c;
			}
		});
		if ($A.util.isEmpty(editNoteBody)) {
			var moreNotes = component.get('v.moreNotes');
			moreNotes.forEach(function(note) {
				if (note.record.Id == editNoteId) {
					editNoteBody = note.record.Notes__c;
                    editIsVisibleToCS = note.record.IsVisibleToCS__c;
				}
			});
		}
		component.set('v.editNoteBody', editNoteBody);
        component.set('v.editIsVisibleToCS', editIsVisibleToCS);
		component.set('v.showEditNoteModal', true);
	},
	updateNote: function(component, event, helper) {
		var incidentNote = {
			Id: component.get('v.editNoteId'),
			Notes__c: component.get('v.editNoteBody'),
            IsVisibleToCS__c: component.get('v.editIsVisibleToCS')
		};
		helper.upsertNote(component, incidentNote);
		helper.clearEditNote(component);
		component.set('v.showEditNoteModal', false);
	},
	cancelNoteEdit: function(component, event, helper) {
		helper.clearEditNote(component);
		component.set('v.showEditNoteModal', false);
	},

	readMore: function(component, event, helper) {
        var noteId = event.currentTarget.dataset.id;
        console.log(noteId);

        var fullNote = '#f_' + noteId;
        var partialNote = '#p_' + noteId;

        console.log(fullNote);
        console.log(partialNote);

        $(fullNote).removeClass('slds-hide');
        $(partialNote).addClass('slds-hide');
    },

    hideNote: function(component, event, helper) {
        var noteId = event.currentTarget.dataset.id;
        console.log(noteId);

        var fullNote = '#f_' + noteId;
        var partialNote = '#p_' + noteId;

        console.log(fullNote);
        console.log(partialNote);

        $(fullNote).addClass('slds-hide');
        $(partialNote).removeClass('slds-hide');
    },
})