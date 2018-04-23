/*******************************************************************************
*                                                                              *
*                                           ########                           *
*                                            #####                             *
*    Copyright (c) 2017 Thumbtack            ###                               *
*       All rights reserved.                ###                                *
*                                         #####                                *
*                                      #########                               *
*                                         #                                    *
*                                        #                                     *
*                                       #                                      *
*                                      #                                       *
*                                                                              *
********************************************************************************
Change List:

Version      Date          Author            Description
========+============+=================+================================================
1.0      2017-08-22   Mendel Guillaume       Created
========+============+=================+===============================================*/
({
    doInit: function(component, event, helper)
    {
        helper.loadPriorities(component, helper);
    },

    editClick: function(component, event, helper)
    {
        helper.clearMessage(component);
        component.set('v.showModal', true);
    },

    clearCaseFlagsClick: function(component, event, helper)
    {
        var incident = component.get('v.incident');

        incident.NewEmailFlag__c = false;
        incident.NewPostFlag__c = false;
        incident.NewCallFlag__c = false;
        incident.NewCaseFlag__c = false;

        component.set('v.incident', incident);

        helper.save(component, false);
    },

    closeIncidentModalClick: function(component, event, helper)
    {
        helper.clearMessage(component);
        component.set('v.showCloseModal', true);
    },

    cancelClick: function(component, event, helper)
    {
        helper.reloadIncident(component);
        helper.closeModal(component);
        helper.clearMessage(component);
    },

    cancelCloseClick: function(component, event, helper)
    {
        helper.reloadIncident(component);
        helper.closeCloseModal(component);
        helper.clearMessage(component);
    },

    saveClick: function(component, event, helper)
    {
        helper.save(component, false);
    },

    closeIncidentClick: function(component, event, helper)
    {
        var valid = true;
        var category = component.find('category');
        var subCategory = component.find('subCat');
        var origin = component.find('origin');
        var outcomePro = component.find('outcomePro');
        var outcomeCustomer = component.find('outcomeCustomer');
        var subCats = component.get('v.subCategories');
       // var amountInDispute = component.find('amountInDispute');

        if(!category.get('v.validity').valid)
        {
            category.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!origin.get('v.validity').valid)
        {
            origin.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!outcomePro.get('v.validity').valid)
        {
            outcomePro.showHelpMessageIfInvalid();
            valid = false;
        }

        if(!outcomeCustomer.get('v.validity').valid)
        {
            outcomeCustomer.showHelpMessageIfInvalid();
            valid = false;
        }

        /*if(amountInDispute.get('v.value') == null || amountInDispute.get('v.value') == '')
        {
            component.set('v.showAmountError', true);
            valid = false;
        }
        else
        {
            component.set('v.showAmountError', false);
        }*/

        if(subCats != null && subCats.length > 0)
        {
            if(!subCategory.get('v.validity').valid)
            {
                subCategory.showHelpMessageIfInvalid();
                valid = false;
                //console.log('Sub cat required');
            }
        }

        if(valid)
        {
            helper.save(component, true);
        }
    },

    closeToastClick: function(component, event, helper)
    {
        helper.clearMessage(component);
    },

    onCategoryChange: function(component, event, helper)
    {
        console.log('on cat change');
        var incident = component.get('v.incident');

        incident.MISubcategory__c = null;

        helper.setSubCategories(component, null);
    },
})