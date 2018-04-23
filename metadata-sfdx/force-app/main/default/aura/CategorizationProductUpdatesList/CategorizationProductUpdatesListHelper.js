/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-27   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({
    loadProductUpdates : function(component)
    {
        var action = component.get('c.getProductUpdates');

        action.setParam('recordId', component.get('v.recordId'));

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS')
            {
                component.set('v.productUpdates', response.getReturnValue());
                this.showSentimentColumn(component);
            }
            else if (state === 'ERROR')
            {
                // error handling goes here
                console.log('error loadProductUpdates')
            }
        });

        $A.enqueueAction(action);
    },

    saveProductUpdates : function(component)
    {
        var action = component.get('c.updateCategorization');
        var productUpdates = component.get('v.productUpdates');
        var catsToSave = [];
        var missingSentiment = false;

        component.set('v.showSpinner', true);
        this.clearMessage(component);

        console.log('saveProductUpdates');

        for(var i = 0; i < productUpdates.length; i++)
        {
            productUpdates[i].category.sobjectType = 'Categorization__c';

            if(productUpdates[i].selected || productUpdates[i].category.Id != null)
            {
                console.log('save: ' + productUpdates[i].category);

                productUpdates[i].category.Deleted__c = !productUpdates[i].selected;

                if(productUpdates[i].category.Deleted__c)
                {
                    productUpdates[i].category.Sentiment__c = null;
                    productUpdates[i].category.Notes__c = null;
                }
                else if(productUpdates[i].sentimentScale != null && productUpdates[i].sentimentScale != '0' &&
                    (productUpdates[i].category.Sentiment__c == null || productUpdates[i].category.Sentiment__c == 0))
                {
                    missingSentiment = true;
                }

                catsToSave.push(productUpdates[i].category);
            }
            else if(productUpdates[i].isParent)
            {
                for(var j = 0; j < productUpdates[i].childCategories.length; j++)
                {
                    productUpdates[i].childCategories[j].category.sobjectType = 'Categorization__c';

                    if(productUpdates[i].childCategories[j].selected || productUpdates[i].childCategories[j].category.Id != null)
                    {
                        productUpdates[i].childCategories[j].category.Deleted__c = !productUpdates[i].childCategories[j].selected;

                        if(productUpdates[i].childCategories[j].category.Deleted__c)
                        {
                            productUpdates[i].childCategories[j].category.Sentiment__c = null;
                            productUpdates[i].childCategories[j].category.Notes__c = null;
                        }
                        else if(productUpdates[i].childCategories[j].sentimentScale != null && productUpdates[i].childCategories[j].sentimentScale != '0' &&
                            (productUpdates[i].childCategories[j].category.Sentiment__c == null || productUpdates[i].childCategories[j].category.Sentiment__c == 0))
                        {
                            missingSentiment = true;
                        }

                        catsToSave.push(productUpdates[i].childCategories[j].category);
                    }
                }
            }
        }

        if(missingSentiment)
        {
            component.set('v.message', 'Sentiment is required for product updates.');
        }

        if(catsToSave.length > 0 && !missingSentiment)
        {
            action.setParam('catsToSave', catsToSave);

            action.setCallback(this, function(response) {
                var state = response.getState();

                if (state === 'SUCCESS')
                {
                    console.log('saveProductUpdates Response: ' + response.getReturnValue());
                    var message = component.get('v.message');

                    if(response.getReturnValue() == 'Success')
                    {
                        //Clear child lists - workaround to get rid of duplicated child products when list is "rerendered"
                        for(var i = 0; i < productUpdates.length; i++)
                        {
                            if(productUpdates[i].isParent)
                            {
                                for(var j = 0; j < productUpdates[i].childCategories.length; j++)
                                {
                                    productUpdates[i].childCategories[j].category = null;
                                }
                            }
                        }
                        component.set('v.productUpdates', productUpdates);
                        //end workaround

                        this.loadProductUpdates(component);
                        message = '';
                        var rc = $A.get("e.c:CategorizationEvent");

                        rc.setParam('actionName', 'Refresh Case');
                        rc.setParam('recordId', component.get('v.recordId'));

                        rc.fire();
                    }
                    else
                    {
                        message += 'Error saving product updates: ' + response.getReturnValue();
                        component.set('v.allowSubmit', true);
                    }

                    component.set('v.message', message);
                }
                else if (state === 'ERROR')
                {
                    // error handling goes here
                    console.log('error saveProductUpdates')
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
        var productUpdates = component.get('v.productUpdates');
        var showSentiment = false;

        for(var i = 0; i < productUpdates.length; i++)
        {
            if(productUpdates[i].sentimentScale != null && productUpdates[i].sentimentScale != '0')
            {
                showSentiment = true;
                break;
            }
        }

        component.set('v.showSentiment', showSentiment);
    }
})