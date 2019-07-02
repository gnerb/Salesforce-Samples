import { LightningElement, track, wire, api } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getStateMap from '@salesforce/apex/ContractorSearchController.getStateMap';
import getContractors from '@salesforce/apex/ContractorSearchController.getContractors';
    
import STATE_FIELD from '@salesforce/schema/Requisition__c.State__c';
import CITY_FIELD from '@salesforce/schema/Requisition__c.City__c';
import OSHA_FIELD from '@salesforce/schema/Requisition__c.Osha10__c';
import BACKGROUND_CHECK_FIELD from '@salesforce/schema/Requisition__c.RequiresBackgroundCheck__c';
import DRUG_SCREEN_FIELD from '@salesforce/schema/Requisition__c.RequiresDrugScreen__c';
import VEHICLE_FIELD from '@salesforce/schema/Requisition__c.RequiresVehicle__c';
import SKILL_LEVEL_FIELD from '@salesforce/schema/Requisition__c.SkillLevel__c';
import TRADE_FIELD from '@salesforce/schema/Requisition__c.Trade__c';
import WWID_FIELD from '@salesforce/schema/Requisition__c.WWID__c';

import ASSIGNMENT_OBJECT from '@salesforce/schema/ContractorAssignment__c';
import CONTRACTOR_FIELD from '@salesforce/schema/ContractorAssignment__c.Contractor__c';
import REQUISION_FIELD from '@salesforce/schema/ContractorAssignment__c.Requisition__c';

const requisitionFields = [
    STATE_FIELD, CITY_FIELD, OSHA_FIELD, BACKGROUND_CHECK_FIELD, DRUG_SCREEN_FIELD,
    VEHICLE_FIELD, SKILL_LEVEL_FIELD, TRADE_FIELD, WWID_FIELD
];

const columns = [
    {fieldName:"Name",label:"Name",sortable:true},
    {fieldName:"Email",label:"Email",sortable:true},
    {fieldName:"Phone",label:"Phone",sortable:true}
];

export default class testLwc extends LightningElement {
    @api recordId;
    @track requisition;

    @track states;
    @track cities;
    @track stateMap;
    @track contractors;
    @track columns = columns;
    @track tradeOptions;
    @track skillLevelOptions;
    
    @track selectedState;
    @track selectedCity;
    @track selectedSkillLevel;
    @track selectedOSHA;
    @track selectedWWID;
    @track selectedBackgroundCheck;
    @track selectedTrade;
    @track selectedDrugScreen;
    @track selectedTrade;
    @track selectedVehicle;
    @track selectedContractors;

    @wire(getPicklistValues, {recordTypeId:'0124N000000SggEQAS',fieldApiName: SKILL_LEVEL_FIELD})
    setSkillLevelOptions({data, error}) {
        if (data) {
            this.skillLevelOptions = data.values;

            if (this.selectedSkillLevel) {
                let isValid = this.skillLevelOptions.some(function(skill) {
                    return skill === this.selectedSkillLevel;
                }, this);

                if (!isValid) {
                    this.selectedSkillLevel = data.defaultValue;
                }
            } else {
                this.selectedSkillLevel = data.defaultValue;
            }
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating assignment',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        }
    }

    @wire(getPicklistValues, {recordTypeId:'0124N000000SggEQAS',fieldApiName: TRADE_FIELD})
    setTradeOptions({data, error}) {
        if (data) {
            this.tradeOptions = data.values;

            if (this.selectedTrade) {
                let isValid = this.tradeOptions.some(function(trade) {
                    return trade === this.selectedTrade;
                }, this);

                if (!isValid) {
                    this.selectedTrade = data.defaultValue;
                }
            } else {
                this.selectedTrade = data.defaultValue;
            }
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating assignment',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        }
    }

    @wire(getRecord, {recordId:'$recordId', fields:requisitionFields})
    getRequisition({error, data}) { 
        this.contractors = undefined;
        this.selectedContractors = undefined;

        getStateMap().then(
            result => {
                let keys = Reflect.ownKeys(result);
                let s = [];
                this.stateMap = [];

                keys.forEach(function(stateName) {
                    let c = [];

                    result[stateName].forEach(function(cityName) {
                        c.push({label: cityName, value:cityName});
                    }, this);

                    s.push({label:stateName, value:stateName});
                    this.stateMap[stateName] = c;
                }, this);

                this.states = s;
                
                if (data && this.stateMap) {
                    this.requisition = data;
                    let stateName = getFieldValue(data, STATE_FIELD);
                    let cityName = getFieldValue(data, CITY_FIELD);
                    let skillLevel = getFieldValue(data, SKILL_LEVEL_FIELD);
                    let trade = getFieldValue(data, TRADE_FIELD);

                    let hasState = this.states.some(function(state) {
                        return state.value === stateName
                    }, this);
        
                    if (hasState) {
                        this.selectedState = stateName;
                        this.cities = this.stateMap[this.selectedState];

                        let hasCity = this.cities.some(function(city) {
                            return city.value === cityName;
                        }, this);

                        if (hasCity) {
                            this.selectedCity = cityName;
                        } else {
                            this.selectedCity = this.cities[0].value;
                        }
                    } else {
                        this.selectedState = this.states[0].value;
                        this.cities = this.stateMap[this.selectedState];
                        this.selectedCity = this.cities[0].value;
                    }

                    if (this.tradeOptions) {
                        let hasTrade = this.tradeOptions.some(function(option) {
                            return option.value === trade;
                        }, this);

                        if (hasTrade) {
                            this.selectedTrade = trade;
                        } else if (!this.selectedTrade) {
                            this.selectedTrade = this.tradeOptions[0].value;
                        }
                    } else {
                        this.tradeOptions = [{value:trade, label:trade}];
                        this.selectedTrade = this.tradeOptions[0].value;
                    }

                    if (this.skillLevelOptions) {
                        let hasSkill = this.skillLevelOptions.some(function(option) {
                            return option.value === skillLevel;
                        }, this);

                        if (hasSkill) {
                            this.selectedSkillLevel = skillLevel;
                        } else if (!this.selectedSkill) {
                            this.selectedSkillLevel = this.skillLevelOptions[0].value;
                        }
                    } else {
                        this.skillLevelOptions = [{value:skillLevel, label:skillLevel}];
                        this.selectedSkillLevel = this.skillLevelOptions[0].value;
                    }
        
                    this.selectedDrugScreen = getFieldValue(data, DRUG_SCREEN_FIELD);
                    this.selectedOSHA = getFieldValue(data, OSHA_FIELD);
                    this.selectedWWID = getFieldValue(data, WWID_FIELD);
                    this.selectedBackgroundCheck = getFieldValue(data, BACKGROUND_CHECK_FIELD);
                    this.selectedVehicle = getFieldValue(data, VEHICLE_FIELD);
                } else if (error) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating assignment',
                            message: error.body.message,
                            variant: 'error',
                        }),
                    );
                }
            }
        ).catch(
            result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating assignment',
                        message: result.body.message,
                        variant: 'error',
                    }),
                );
            }
        );
    }

    handleStateChange(event) {
        this.selectedState = event.detail.value;
        this.cities = this.stateMap[this.selectedState];
        this.selectedCity = this.cities[0].value;
    }

    handleCityChange(event) {
        this.selectedCity = event.detail.value;
    }

    handleOSHAClick(event) {
        this.selectedOSHA = event.target.checked;
    }

    handleDrugScreenClick(event) {
        this.selectedDrugScreen = event.target.checked;
    }

    handleBackgroundClick(event) {
        this.selectedBackgroundCheck = event.target.checked;
    }

    handleTradeClick(event) {
        this.selectedTrade = event.target.checked;
    }

    handleVehicleClick(event) {
        this.selectedVehicle = event.target.checked;
    }

    handleWWIDClick(event) {
        this.selectedWWID = event.target.checked;
    }

    handleSkillChange(event) {
        this.selectedSkillLevel = event.detail.value;
    }

    handleTradeChange(event) {
        this.selectedTrade = event.detail.value;
    }

    handleSearchClick() {
        this.selectedContractors = undefined;

        getContractors({
            state:this.selectedState,
            city:this.selectedCity,
            osha:this.selectedOSHA, 
            vehicle:this.selectedVehicle, 
            drugscreen:this.selectedDrugScreen,
            wwid:this.selectedWWID, 
            backgroundcheck:this.selectedBackgroundCheck,
            skillLevel:this.selectedSkillLevel, 
            trade:this.selectedTrade
        }).then(
            result => {
                this.contractors = result && result.length > 0 ? 
                    result : undefined;

                if (!this.contractors) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'info',
                            message: 'Search Completed With No Results',
                            variant: 'info'
                        })
                    );
                }
            }
        ).catch(
            error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error searching',
                        message: error,
                        variant: 'error'
                    })
                );
            }
        );
    }

    handleRowSelection(event) {
        this.selectedContractors = event.detail.selectedRows;
        if (!this.selectedContractors || this.selectedContractors.length <= 0) {
            this.selectedContractors = undefined;
        }
    }

    // Possibly handle duplicates?
    // Could also just create dup rules..
    handleAssignClick() {
        this.selectedContractors.forEach(function(contractor) {
            let fields = {};
            fields[CONTRACTOR_FIELD.fieldApiName] = contractor.Id;
            fields[REQUISION_FIELD.fieldApiName] = this.requisition.id;
            let record = {apiName: ASSIGNMENT_OBJECT.objectApiName, fields};

            createRecord(record).then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Contractor Assigned',
                        variant: 'success',
                    })
                );

                //this.selectedContractors = undefined;
            }).catch(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating assignment',
                        message: result.body.message,
                        variant: 'error',
                    })
                );
            });
        }, this);
    }
}