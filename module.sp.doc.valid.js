/**
 * @license sgJS v1.0.1
 * (c) 2017 SurplusGLOBAL, Inc. http://codejs.surplugglobal.com
 * License: SG only(confidential)
 */
(function (window) {

    /**
     * @description
     *
     * This object provides a utility for producing rich Error messages within
     * SGGGGGG. It can be called as follows:
     *
     *
     * @param {string} module The namespace to use for the new minErr instance.
     * @param {function} ErrorConstructor Custom error constructor to be instantiated when returning
     *   error from returned function, for cases when a particular type of error is useful.
     * @returns {function(code:string, template:string, ...templateArgs): Error} minErr instance
     */
    'use strict';

    function module(kind, funcNm4Callback) {
        switch (kind) {
            case '':
                break;
            default:
                break;
        }
    }

    function base(name, func){
        this._name = name;      
    }

    base.prototype = Object.create(nuill, {
        contructor: {
            value: base
        },
        valid:{valule:function(){
            return 'my Name is ' + this._name;
        }}
    })

    function validToDoc(name, func){
        base.apply(this, arguments);
        this.module = {
            init:function(){
                //-
            },
            beforeSave:function(){

                func(data);
            }
        }
    }

    validToDoc.prototype = Object.create(base.prototype, {
        constructor: {
            value:validToDoc
        },
        valid:{
            value:function(){
                var superClassPrototype = Object.getPrototypeOf(this.contructor.prototype);
                return '[validToDoc]' + superClassPrototype.valid.call(this);
            }
        }
    });

})(window);

//Update before
var formV = new validToDoc({
    args : ['docId'],
    success:function(data){
        if (data){
            alert(data.messages.first);
        }
    }
});

//Equip Update before
//Request before
