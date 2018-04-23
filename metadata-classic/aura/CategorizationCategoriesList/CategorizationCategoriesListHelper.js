/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-24   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({
    loadOrigins: function(component)
    {
        var action = component.get("c.getOrigins");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if(component.isValid() && state == "SUCCESS")
            {
                component.set('v.origins', response.getReturnValue());
            }
            else
            {
                console.log('Failed: ' + state);
            }
        });

        $A.enqueueAction(action); 
    },

    loadCategories : function(component)
    {
        var action = component.get('c.getCategories');

        action.setParam('recordId', component.get('v.recordId'));

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                component.set('v.categories', response.getReturnValue());
                this.showSentimentColumn(component);
                this.setPrimaryCategory(component);
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error loadCategories');
            }
        });

        $A.enqueueAction(action);
    },

    addNewCategory : function(component, catDefKey, parentCatDefKey)
    {
        var allCats = component.get('v.categories');
        var action = component.get('c.addCategory');
        var exists = false;

        for(var i = 0; i < allCats.length; i++)
        {
            if(allCats[i].category.DefinitionKey__c == catDefKey)
            {
                exists = true;
                allCats[i].category.Deleted__c = false;
                break;
            }
        }

        if(!exists)
        {
            action.setParam('catDefKey', catDefKey);
            action.setParam('recordId', component.get('v.recordId'));

            action.setCallback(this, function(response) {
                var state = response.getState();

                if (state === 'SUCCESS')
                {
                    var newCat = response.getReturnValue();

                    if(newCat != null)
                    {
                        allCats.push(newCat);

                        if(allCats.length == 1)
                        {
                            allCats[0].category.Primary__c = true;
                        }

                        component.set('v.categories', allCats);
                        component.set('v.allowSubmit', true);
                        this.showSentimentColumn(component);
                        this.setPrimaryCategory(component);
                    }
                }
                else if (state === 'ERROR')
                {
                    // error handling goes here
                    console.log('error addNewCategory');
                }
            });

            $A.enqueueAction(action);
        }
        else
        {
            component.set('v.categories', allCats);
            component.set('v.allowSubmit', true);
            this.showSentimentColumn(component);
            this.setPrimaryCategory(component);
        }
    },

    removeCategory : function(component, catDefKey, parentCatDefKey)
    {
        var allCats = component.get('v.categories');
        var index = -1;

        for(var i = 0; i < allCats.length; i++)
        {
            if(allCats[i].category.DefinitionKey__c == catDefKey)
            {
                index = i;
                allCats[i].category.Deleted__c = true;
                allCats[i].category.Primary__c = false;
                break;
            }
        }

        if(index > -1)
        {
            component.set('v.categories', allCats);
            component.set('v.allowSubmit', true);
            this.showSentimentColumn(component);
            this.setPrimaryCategory(component);
        }
    },

    saveCategories : function(component)
    {
        console.log('saveCategories');
        var action = component.get('c.updateCategorization');
        var categories = component.get('v.categories');
        var catsToSave = [];

        component.set('v.showSpinner', true);
        this.clearMessage(component);

        for(var i = 0; i < categories.length; i++)
        {
            categories[i].category.sobjectType = 'Categorization__c';

            catsToSave.push(categories[i].category);
        }

        if(catsToSave.length > 0)
        {
            action.setParam('catsToSave', catsToSave);

            action.setCallback(this, function(response) {
                var state = response.getState();

                if (state === 'SUCCESS')
                {
                    var message = component.get('v.message');

                    if(response.getReturnValue() == 'Success')
                    {
                        this.loadCategories(component);
                        message = '';

                        var ce = $A.get("e.c:CategorizationEvent");

                        ce.setParam('actionName', 'Refresh Tree');
                        ce.setParam('recordId', component.get('v.recordId'));

                        ce.fire();

                        var rc = $A.get("e.c:CategorizationEvent");

                        rc.setParam('actionName', 'Refresh Case');
                        rc.setParam('recordId', component.get('v.recordId'));

                        rc.fire();
                    }
                    else
                    {
                        message += 'Error saving categories: ' + response.getReturnValue();
                        component.set('v.allowSubmit', true);
                    }

                    component.set('v.message', message);
                }
                else if (state === 'ERROR')
                {
                    // error handling goes here
                    console.log('error saveCategories');
                }

                component.set('v.showSpinner', false);
            });

            $A.enqueueAction(action);
        }
        else
        {
            component.set('v.showSpinner', false);
        }
    },

    clearMessage: function(component)
    {
        component.set('v.message', '');
    },

    showSentimentColumn: function(component)
    {
        var allCats = component.get('v.categories');
        var showSentiment = false;

        for(var i = 0; i < allCats.length; i++)
        {
            if(allCats[i].sentimentScale != null && allCats[i].sentimentScale != '0')
            {
                showSentiment = true;
                break;
            }
        }

        component.set('v.showSentiment', showSentiment);
    },

    setPrimaryCategory : function(component)
    {
        var allCats = component.get('v.categories');
        var primaryIndex = -1;
        var primaryCount = 0;

        component.set('v.primaryCategory', '');
        component.set('v.primarySubcategory', '');

        //Get index of primary category or category to be set as primary
        for(var i = 0; i < allCats.length; i++)
        {
            if(!allCats[i].category.Deleted__c)
            {
                if(!allCats[i].category.Primary__c)
                {
                    if(primaryIndex == -1)
                    {
                        primaryIndex = i;
                    }
                }
                else
                {
                    primaryIndex = i;
                    primaryCount++;
                    break;
                }
            }
        }

        if(primaryCount == 0 && primaryIndex > -1)
        {
            allCats[primaryIndex].category.Primary__c = true;
            component.set('v.categories', allCats);
        }

        if(primaryIndex > - 1)
        {
            component.set('v.primaryCategory', allCats[primaryIndex].category.Category__c);
            component.set('v.primarySubcategory', allCats[primaryIndex].category.Subcategory__c);
        }
    },
})