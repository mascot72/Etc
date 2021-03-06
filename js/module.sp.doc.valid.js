/**
* @license ILib Template CODE v1.0.1
* (c) 2017 Isaac Choi, Inc. http://codejs.joyhobby.com
* License: Author only(confidential)
*/
(function (window) {

  /**
  * @description
  *
  * This object provides a utility for producing rich Error messages within
  * IoT, SPA. It can be called as follows:
  * My Idea code play
  *
  * @param {string} module The namespace to use for the new minErr instance.
  * @param {function} ErrorConstructor Custom error constructor to be instantiated when returning
  *   error from returned function, for cases when a particular type of error is useful.
  * @returns {function(code:string, template:string, ...templateArgs): Error} minErr instance
  */
  'use strict';

  var vm;

  function module(kind, funcNm4Callback) {
    switch (kind) {
      case '':
      break;
      default:
      break;
    }
  }

  function base(name, func){
    //this._name = name;
    vm = this;
  }

  base.prototype = Object.create(null, {
    contructor: {
      value: base
    },
    valid:{valule:function(){
      return 'my Name is ' + this._name;
    }}
  });

  function validToDoc(name, func){
    base.apply(this, arguments);
    this.module = {
      init:function(){
        //-
      },
      beforeSave:function(data){

        func(data);
      }
    };
  }

  window.iLib = window.iLib || new validToDoc('isaac', (data) => { console.log(data); });

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
// var formV = new validToDoc({
//   args : ['docId'],
//   success:function(data){
//     if (data){
//       alert(data.messages.first);
//     }
//   }
// });


//Equip Update before
//Request before


//Ajax Bloking회피하기위해 Interval처리
//myVar = setInterval(function(){ initTimer(); }, 500);    //0.5초마다
var myVar;  //tiemer flag Object
var excutedCnt = 0; //실행된 수
var isSavedStage = false;   //Header저장종료여부
function stopInitTimer() {
  clearInterval(myVar);
}
function initTimer(){
  if (excutedCnt > 400){	//timeout:200,000msec : 무한기다림 회피
    stopInitTimer();
  } else if (isSavedStage){
    stopInitTimer();	//Timer소멸
    isSavedStage = false;
    //call PDF Popup
    openPackagePDF();
  }
  excutedCnt++;
}
