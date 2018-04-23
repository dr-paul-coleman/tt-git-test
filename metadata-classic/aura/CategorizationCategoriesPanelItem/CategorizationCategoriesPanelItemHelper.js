/*
   Copyright (c) 2017 Thumbtack. All rights reserved.

   Version      Date          Author            Description
   ========+============+=================+================================================
   1.0      2017-10-24   Mendel Guillaume       Created
   ========+============+=================+===============================================
*/
({

    handleSubCategorySelection : function(component, catId, subId)
    {
        var categoryType = component.get('v.ct');

        for(var i = 0; i < categoryType.categories.length; i++)
        {
            var categoryWrapper = categoryType.categories[i];

            if(categoryWrapper.category.Id == catId)
            {
                for(var j = 0; j < categoryWrapper.subCategories.length; j++)
                {
                    var subCatWrapper = categoryWrapper.subCategories[j];

                    if(subCatWrapper.category.Id == subId)
                    {
                        if(subCatWrapper.selected)
                        {
                            subCatWrapper.selected = false;
                            categoryWrapper.subSelected = false;

                            for(var k = 0; k < categoryWrapper.subCategories.length; k++)
                            {
                                var subCatWrapper2 = categoryWrapper.subCategories[k];

                                if(subCatWrapper2.selected)
                                {
                                    categoryWrapper.subSelected = true;
                                    break;
                                }
                            }

                            this.fireCategorizationEvent(component, 'Remove Category - Tree', subCatWrapper.category.Key__c, categoryWrapper.category.Key__c);
                        }
                        else
                        {
                            subCatWrapper.selected = true;
                            categoryWrapper.subSelected = true;
                            this.fireCategorizationEvent(component, 'Add New Category - Tree', subCatWrapper.category.Key__c, categoryWrapper.category.Key__c);
                        }

                        break;
                    }
                }

                break;
            }
        }

        component.set('v.ct', categoryType);

    },

    fireCategorizationEvent : function(component, actionName, catDefKey, parentCatDefKey)
    {
        var ce = $A.get("e.c:CategorizationEvent");

        ce.setParam('actionName', actionName);
        ce.setParam('recordId', component.get('v.recordId'));
        ce.setParam('catDefKey', catDefKey);
        ce.setParam('parentCatDefKey', parentCatDefKey);

        ce.fire();
    },

    toggleCategory : function(component, catDefKey, parentCatDefKey, selected)
    {
        var categoryType = component.get('v.ct');

        for(var i = 0; i < categoryType.categories.length; i++)
        {
            var categoryWrapper = categoryType.categories[i];

            if(categoryWrapper.category.Key__c == parentCatDefKey)
            {
                for(var j = 0; j < categoryWrapper.subCategories.length; j++)
                {
                    var subCatWrapper = categoryWrapper.subCategories[j];

                    if(subCatWrapper.category.Key__c == catDefKey)
                    {
                        if(!selected)
                        {
                            subCatWrapper.selected = false;
                            categoryWrapper.subSelected = false;

                            for(var k = 0; k < categoryWrapper.subCategories.length; k++)
                            {
                                var subCatWrapper2 = categoryWrapper.subCategories[k];

                                if(subCatWrapper2.selected)
                                {
                                    categoryWrapper.subSelected = true;
                                    break;
                                }
                            }
                        }
                        else
                        {
                            subCatWrapper.selected = true;
                            categoryWrapper.subSelected = true;
                        }

                        break;
                    }
                }

                break;
            }
        }

        component.set('v.ct', categoryType);
    },
})