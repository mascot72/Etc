﻿<%@page import="java.util.Map"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib uri="http://www.springframework.org/tags" prefix="spring"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<!-- ///////////////////////////////////////////////////////////
/*
/* FileName   : SP0300M
/* Description: Quote/Purchase Order/Invoice Create (26 jan 2017) 작업중
/*
////////////////////////////////////////////////////////////////  -->
<html lang="ko">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<title>Quote/Purchase/Order/Invoice Create</title>
<link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/common/bootstrap/css/bootstrap-3.3.6.min.css">
<jsp:include page="../common/include_file.jsp" flush="false" />
<script type="text/javascript" src="${pageContext.request.contextPath}/common/bootstrap/js/bootstrap.min.js"></script>
<!-- File Attachment script file-->
<script type="text/javascript" src="./view/common/attachFileList.js"></script>
<script type="text/javascript" src="./view/common/approval.js"></script>

<script>
    $(document).ready(function() {
        $('a.close_lnb').click(function() {
            jQuery('div.cDs_open').hide(0);
            jQuery('div.cDs_close').show(0);
            jQuery('section.tree_lnb').removeClass('open');
        });
        $('a.open_lnb').click(function() {
            jQuery('div.cDs_open').show(0);
            jQuery('div.cDs_close').hide(0);
            jQuery('section.tree_lnb').addClass('open');
        });

        $("#chk_warrTerm:checkbox").change(function () {
            if($(this).is(":checked")) {
                $("#warrTermYn").val("Y");
            } else {
                $("#warrTermYn").val("N");
            }
        });

        $("#chk_warrLabor:checkbox").change(function () {
            if($(this).is(":checked")) {
                $("#warrLaborYn").val("Y");
            } else {
                $("#warrLaborYn").val("N");
            }
        });

        $("#chk_warrPart:checkbox").change(function () {
            if($(this).is(":checked")) {
                $("#warrPartYn").val("Y");
            } else {
                $("#warrPartYn").val("N");
            }
        });

        $("#chk_priceTerm:checkbox").change(function () {
            if($(this).is(":checked")) {
                $("#priceTermYn").val("Y");
            } else {
                $("#priceTermYn").val("N");
            }
        });

        $("#chk_packType:checkbox").change(function () {
            if($(this).is(":checked")) {
                $("#packTypeYn").val("Y");
            } else {
                $("#packTypeYn").val("N");
            }
        });

        $("#chk_packRes:checkbox").change(function () {
            if($(this).is(":checked")) {
                $("#packResYn").val("Y");
            } else {
                $("#packResYn").val("N");
            }
        });

        $("#chk_ship:checkbox").change(function () {
            if($(this).is(":checked")) {
                $("#shipYn").val("Y");
            } else {
                $("#shipYn").val("N");
            }
        });

        $("#chk_bank:checkbox").change(function () {
            if($(this).is(":checked")) {
                $("#bankYn").val("Y");
            } else {
                $("#bankYn").val("N");
            }
        });

        $("#chk_validity:checkbox").change(function () {
            if($(this).is(":checked")) {
                $("#validityYn").val("Y");
            } else {
                $("#validityYn").val("N");
            }
        });

        $("#chk_delivery:checkbox").change(function () {
            if($(this).is(":checked")) {
                $("#deliveryYn").val("Y");
            } else {
                $("#deliveryYn").val("N");
            }
        });

        $("#chk_remark:checkbox").change(function () {
            if($(this).is(":checked")) {
                $("#remarkYn").val("Y");
            } else {
                $("#remarkYn").val("N");
            }
        });
        
		//event bind to collapse(하단의 IBSheet2개 영역)
		$('.btnPayTermsView, .btnPdfView').click(function(args){
    		 var targetId = $(this).attr('data-target');
    		 $('#'+targetId).parent().toggle();
    		 
    		 $(this).text(function(i, text){
    			 return text === 'Show' ? 'Hide' : 'Show';
    		 });
		});
		//장비영역
		$('.btnEquipsView').click(function(args){
   		 var targetId = $(this).attr('data-target');
   		 
   		 $(this).text(function(i, text){
   			 return text === 'Show' ? 'Hide' : 'Show';
   		 });
   		 doAction('FullHeightByEquip');
		});
		
		/*[추가-시작]file Attachmet에 필요한 변수값 설정(10 jan 2017)*/
		//결재초기화
		initApproval();
		initSheet_F();
		initButton_F();		
		/*[추가-끝]*/
		
		//결재이후 첨부가능자 조회(날인Contract관련자)
		getCommonCode('AUTH_PAY_APPR_SAVE', function(data){
        	paytermsAuthUsers = data;	
        });

    });
    /*=============================================
     * Quote/Purchase/Order/Invoice Create.
     ----------------------------------------------*/
    var mySheetTree = new ibsheetObject();
    var mySheet = new ibsheetObject();
    var mySheetEquip = new ibsheetObject();
    var mySheetPay = new ibsheetObject();

    var popWin = null; //-- PopUp
    var Result = null; //-- Frm_Validation
    var SaveEquipResult = null; //-- Equip Save After Result.
    var SavePayResult = null; //-- Pay Save After Result.

    var tempCnt = 0; //-- Temp Maker/Model Count.
    var selEquipYn = "N"; //-- Equipment Select YN

    //-----------------------------------
    //-- Auto PO 생성 : Offer저장 -> Offer Approval -> PO Create
    //-- Stage별 체크사항과 결재처리가 있으므로 기존로직으로 처리되야 함.
    //-- 조회가 순서적으로 일어나지 않음. 따라서, 각 조회체크(Deal/Equip/Payterm모두 조회후 PO생성되야 하므로)
    var autoAppYn = ""; //-- Auto Po 생성여부
    var autoAppResult = ""; //-- Auto Approval Result.
    var autoSearchDeal = ""; //-- Auto Approval 처리 후, PO 생성위한 Deal          조회여부
    var autoSearchEquip = ""; //-- Auto Approval 처리 후, PO 생성위한 Equipment     조회여부
    var autoSearchPay = ""; //-- Auto Approval 처리 후, PO 생성위한 Payment Terms 조회여부
    //-----------------------------------

    //-- Original Value Set.
    var docIdOrg = "";
    var relIdOrg = "";
    var docTitleOrg = "";
    var currencyOrg = "";
    var exRateOrg = "";
    var equipAmountOrg = "";
    var appYnOrg = "";
    var appMMYnOrg = "";
    var unitPriceSumOrg = 0;
    var buyCompIdOrg = "";
    var buyCompNmOrg = "";
    var docBuyCompNmOrg = "";
    var sellCompIdOrg = "";
    var sellCompNmOrg = "";
    var docSellCompNmOrg = "";
    var offerTypeOrg = "";  //이전문서의 offerType
    var attaGrpIdOrg = "";	//초기 로딩문서의 첨부ID

    var tmCidDiv1Html = "";
    var tmpDisplayDiv1Html = "";
    var tmpPersonDiv1Html = "";
    var tmpPersonDisplayDiv1Html = "";

    var tmCidDiv2Html = "";
    var tmpDisplayDiv2Html = "";
    var tmpPersonDiv2Html = "";
    var tmpPersonDisplayDiv2Html = "";
    var firstView = true;	//최초 화면 로딩시 한번만 실행한는 로직에서 필요함(외부모듈에서 호출시 기본 값 세팅)
	
    /*결재관련 변수*/
	var loginUserId = '<%=session.getAttribute("userId") %>';
	var loginUserNm = '<%=session.getAttribute("userNm") %>';
	
    <%--결재쪽에서 Leader , Management--%>
    var appLeaderId = "${ApprData.leaderUserId}";
    var appMmId     = "${ApprData.mmUserId}";    
    var apprData = {reqUserNm:'${ApprData.reqUserNm}',refUserNm:'${ApprData.refUserNm}',leaderUserNm:'${ApprData.leaderUserNm}',mmUserNm:'${ApprData.mmUserNm}'};
    var apprDataEmpty = {reqUserNm:'${ApprData.reqUserNm}',refUserNm:'',leaderUserNm:'',mmUserNm:''};
    
    var isNotFirstSave = true;	//최초 미저장 여부(deal이나 외부 모듈에서 장비가지고 온경우 날아가지 않도록 체크하기 위한 Flag변수)
    var sevingEquip = false;	//async상태이므로 중복조회 안하기 위한 변수
    var savingPay = false;	//저장전 초기값 세팅시 Event타지 않도록 하기위한 변수
    
    var maxId4Pay = 0, maxId4Pdf = 0;	//순번이 오기 위한 변수(PDF, Payterms)
    var paytermsAuthUsers;	//결재이후 첨부 가능자
    
    $(document).ready(function() {

        initSheetTree();
        initSheet();
        doAction("SearchStage");

        window.document.body.scroll = "auto";

        tmCidDiv1Html = $("#cidDiv1").html();
        tmpDisplayDiv1Html = $("#displayDiv1").html();
        tmpPersonDiv1Html = $("#personDiv1").html();
        tmpPersonDisplayDiv1Html = $("#personDisplayDiv1").html();

        tmCidDiv2Html = $("#cidDiv2").html();
        tmpDisplayDiv2Html = $("#displayDiv2").html();
        tmpPersonDiv2Html = $("#personDiv2").html();
        tmpPersonDisplayDiv2Html = $("#personDisplayDiv2").html();
        
        //bank 변경시 정보 세팅
        $('#sellBnk').change(function(){
            var selectedDesc = $(this).find(':selected').attr('desc');
            $('#sellBnkRemark').val(selectedDesc);
        });

    });

    function initSheetTree() {

        var initSheet = {};

        initSheet.Cfg = {SearchMode : smLazyLoad, Page : 10, MergeSheet : msHeaderOnly, AutoFitColWidth:"search|resize|init"};
        initSheet.HeaderMode = {Sort : 0, ColMove : 0, ColResize : 0, HeaderCheck : 0};
        initSheet.Cols = [
            {Header : "Sales Process", SaveName : "selectYn", Type : "Text", Width : 30, Align : "center", FontColor : "blue", Hidden : 1},
            {Header : "Sales Process", SaveName : "codeNm", Type : "Text", MinWidth : 200, Align : "left", TreeCol : 1, Cursor : "pointer"},
            //-- Hidden
            {Header : "Type", SaveName : "cnt", Type : "Text", Width : 200, Align : "left", Hidden : 1},
            {Header : "Type", SaveName : "type", Type : "Text", Width : 200, Align : "left", Hidden : 1},
            {Header : "Group Code", SaveName : "grpCd", Type : "Text", Width : 80, Align : "left", Hidden : 1},
            {Header : "Group Name", SaveName : "grpNm", Type : "Text", Width : 80, Align : "left", Hidden : 1},
            {Header : "Open YN", SaveName : "openYn", Type : "Text", Width : 10, Align : "left", Hidden : 1},
            {Header : "CD", SaveName : "code", Type : "Text", Width : 80, Align : "left", Hidden : 1},
            {Header : "Parent Cd", SaveName : "parentCd", Type : "Text", Width : 80, Align : "left", Hidden : 1},
            {Header : "Level", SaveName : "level", Type : "Text", Width : 80, Align : "left", Hidden : 1},
            {Header : "Select Key", SaveName : "selectKey", Type : "Text", Width : 80, Align : "left", Hidden : 1},
            {Header : "Reference ID", SaveName : "relId", Type : "Text", Width : 80, Align : "left", Hidden : 1},
            {Header : "Color ID", SaveName : "color", Type : "Text", Width : 80, Align : "left", Hidden : 1}];

        //시트 초기화
        IBS_InitSheet(mySheetTree, initSheet);
        mySheetTree.SetRowBackColorI("#EDEDED");
        mySheetTree.SetEditable(0);
        mySheetTree.SetHeaderBackColor("#c7dff5");
        mySheetTree.SetHeaderFontColor("#000000");
    }

    //-- Data Grid
    function initSheet() {

        // 날짜 초기화
        var date = new Date();
        document.getElementById('stageDate').value = getStrYYYYMMDDFromDate(date);
        //document.getElementById('exDate').value = getStrYYYYMMDDFromDate(date);

        //-- Deal ------------------------------------------------
        var initSheet = {};
        initSheet.Cfg = {SearchMode : smLazyLoad, Page : 50};
        initSheet.HeaderMode = {Sort : 1, ColMove : 1, ColResize : 1, HeaderCheck : 1};
        initSheet.Cols = [
            //-- style="display:none"
            {Header : "appYn", SaveName : "appYn", Type : "Text"},
            {Header : "appMMYn", SaveName : "appMMYn", Type : "Text"},
            {Header : "approvalStatusCd", SaveName : "approvalStatusCd", Type : "Text"},
            //{Header:"relAppYn",SaveName:"relAppYn",Type:"Text"},
            {Header : "docId", SaveName : "docId", Type : "Text"},
            {Header : "relId", SaveName : "relId", Type : "Text"},
            {Header : "docTitle", SaveName : "docTitle", Type : "Text"},
            {Header : "docSubj", SaveName : "docSubj", Type : "Text"},
            {Header : "vat", SaveName : "vat", Type : "Text"},
            {Header : "offerType", SaveName : "offerType", Type : "Text"},
            {Header : "poType", SaveName : "poType", Type : "Text"},
            {Header : "contractType", SaveName : "contractType", Type : "Text"},
            {Header : "invoiceType", SaveName : "invoiceType", Type : "Text"},
            {Header : "serDealYn", SaveName : "serDealYn", Type : "Text"},
            {Header : "sellCompId", SaveName : "sellCompId", Type : "Text"},
            {Header : "sellCompNm", SaveName : "sellCompNm", Type : "Text"},
            {Header : "docSellCompNm", SaveName : "docSellCompNm", Type : "Text"},
            {Header : "buyCompId", SaveName : "buyCompId", Type : "Text"},
            {Header : "buyCompNm", SaveName : "buyCompNm", Type : "Text"},
            {Header : "docBuyCompNm", SaveName : "docBuyCompNm", Type : "Text"},

            {Header : "picPersonId", SaveName : "picPersonId", Type : "Text"},
            {Header : "picPersonNm", SaveName : "picPersonNm", Type : "Text"},
            {Header : "docPicPersonNm", SaveName : "docPicPersonNm", Type : "Text"},

            {Header : "fromPicPersonId", SaveName : "fromPicPersonId", Type : "Text"},
            {Header : "fromPicPersonNm", SaveName : "fromPicPersonNm", Type : "Text"},
            {Header : "docFromPicPersonNm", SaveName : "docFromPicPersonNm", Type : "Text"},

            {Header : "equipAmount", SaveName : "equipAmount", Type : "Int", Width : 30},
            {Header : "stageDate", SaveName : "stageDate", Type : "Text", Align : "center", Format : "Ymd"},
            {Header : "currency", SaveName : "currency", Type : "Text"},
            {Header : "seller", SaveName : "seller", Type : "Text", Width : 30},
            {Header : "sellerNm", SaveName : "sellerNm", Type : "Text", Width : 30},
            {Header : "buyer", SaveName : "buyer", Type : "Text", Width : 30},
            {Header : "buyerNm", SaveName : "buyerNm", Type : "Text", Width : 30},
            {Header : "attaGrpId", SaveName : "attaGrpId", Type : "Text"},
            {Header : "remark", SaveName : "remark", Type : "Text"},
            //-----------------
            {Header : "subPriorSalesYn", SaveName : "subPriorSalesYn", Type : "Text"},
            {Header : "warTerms", SaveName : "warTerms", Type : "Text"},
            {Header : "warLaborPeriod", SaveName : "warLaborPeriod", Type : "Text"},
            {Header : "warLaborRemark", SaveName : "warLaborRemark", Type : "Text"},
            {Header : "warLaborDt", SaveName : "warLaborDt", Type : "Text", Align : "center", Format : "Ymd"},
            {Header : "warPartPeriod", SaveName : "warPartPeriod", Type : "Text"},
            {Header : "warPartRemark", SaveName : "warPartRemark", Type : "Text"},
            {Header : "warPartDt", SaveName : "warPartDt", Type : "Text", Align : "center", Format : "Ymd"},
            {Header : "priceTerms", SaveName : "priceTerms", Type : "Text"},
            {Header : "priceCountry", SaveName : "priceCountry", Type : "Text"},
            {Header : "priceRemark", SaveName : "priceRemark", Type : "Text"},
            {Header : "packType", SaveName : "packType", Type : "Text"},
            {Header : "packRemark", SaveName : "packRemark", Type : "Text"},
            {Header : "pcakRespon", SaveName : "pcakRespon", Type : "Text"},
            {Header : "shipBy", SaveName : "shipBy", Type : "Text"},
            {Header : "shipByRemark", SaveName : "shipByRemark", Type : "Text"},
            {Header : "sellBnk", SaveName : "sellBnk", Type : "Text"},
            {Header : "sellBnkRemark", SaveName : "sellBnkRemark", Type : "Text"},
            {Header : "valDate", SaveName : "valDate", Type : "Text", Align : "center", Format : "Ymd"},
            {Header : "deliText", SaveName : "deliText", Type : "Text"},
            {Header : "termsRemark", SaveName : "termsRemark", Type : "Text"},
            //{Header : "offerNo", SaveName : "offerNo", Type : "Text"},
            {Header : "exDate", SaveName : "exDate", Type : "Text", Align : "center", Format : "Ymd"},
            {Header : "exRate", SaveName : "exRate", Type : "Float", PointCount : 2}, // , DefaultValue: 1.00
            {Header : "Deal Type", SaveName : "dealType", Type : "Text"},
            {Header : "Valu ID", SaveName : "valuId", Type : "Text"},
            {Header : "Valu Ver", SaveName : "valuVerId", Type : "Text"},
            {Header : "Oppt ID", SaveName : "opptId", Type : "Text"},
            {Header : "Previous ID", SaveName : "preVerDocId", Type : "Text"},

            //Check box data
            {Header : "warrTermYn",  SaveName : "warrTermYn",  Type : "Text"},
            {Header : "warrLaborYn", SaveName : "warrLaborYn", Type : "Text"},
            {Header : "warrPartYn",  SaveName : "warrPartYn",  Type : "Text"},
            {Header : "priceTermYn", SaveName : "priceTermYn", Type : "Text"},
            {Header : "packTypeYn",  SaveName : "packTypeYn",  Type : "Text"},
            {Header : "packResYn",   SaveName : "packResYn",   Type : "Text"},
            {Header : "shipYn",      SaveName : "shipYn",      Type : "Text"},
            {Header : "bankYn",      SaveName : "bankYn",      Type : "Text"},
            {Header : "validityYn",  SaveName : "validityYn",  Type : "Text"},
            {Header : "deliveryYn",  SaveName : "deliveryYn",  Type : "Text"},
            {Header : "remarkYn",    SaveName : "remarkYn",    Type : "Text"},
            {Header : "customerDocId",SaveName : "customerDocId",    Type : "Text"},
            {Header : "Detail Type", SaveName : "dealDetType", Type : "Text"}];

        //시트 초기화
        IBS_InitSheet(mySheet, initSheet);
        mySheet.SetEditable(0);

        
        //-- Equipment ------------------------------------------------
        initSheet = {};
        initSheet.Cfg = {SearchMode : smLazyLoad, Page : 50, HeaderCheckMode:1, FrozenCol : 7, MergeSheet : msHeaderOnly};
        initSheet.HeaderMode = {Sort : 1, ColMove : 1, ColResize : 1, HeaderCheck : 1};
        initSheet.Cols = [            
            {Header : "No.",			SaveName : "no",		Type : "Text", Width : 30, Align : "right", Edit : 0},
            {Header : "Sel",			SaveName : "sel",		Type : "CheckBox", Width : 50, Align : "center", Transaction : 0},
            {Header : "PDF", SaveName : "pdfYn", Type : "CheckBox", Width : 50, Align : "center", TrueValue : 'Y', FalseValue : 'N'},
            {Header : "EID",			SaveName : "eId",		Type : "Text", Width : 60, Align : "left", Edit : 0},
            {Header : "SG No",			SaveName : "sgInvNo",		Type : "Text", Width : 60, Align : "left", EditLen : 500, Edit : 0},
            {Header : "Maker",			SaveName : "maker",			Type : "Text", Width : 110, Align : "left", KeyField : 1, EditLen : 500},
            {Header : "Model",			SaveName : "model",			Type : "Text", Width : 110, Align : "left", KeyField : 1, EditLen : 500},
            {Header : "Standard Maker",	SaveName : "makerNm",		Type : "Text", Width : 150, Align : "left", Edit : 0},
            {Header : "Standard Model", SaveName : "modelNm",		Type : "Popup", Width : 150, Align : "left"},
            {Header : "Subject",		SaveName : "subject", Type : "ComboEdit", Validation : 1, Width : 120, KeyField : 1, ComboCode : "${subjectCds}", ComboText : "${subjectNms}"},
            {Header : "Unit Price",		SaveName : "unitPrice", Type : "Float", PointCount : 2, Format : "#,###.##", Width : 130, Align : "right", KeyField : 1, FontColor : "#428BCF"},            
            
            {Header : "Category",		SaveName : "categoryCd",	Type : "ComboEdit", Validation : 1, Align : "center", KeyField : 1, Width : 110, Edit : 1, ComboCode : "${bizCateCds}", ComboText : "${bizCateNms}"},            
            {Header : "Process",			SaveName : "processNm",		Type : "Text", Width : 100, Align : "left", EditLen : 500, FontColor : "#428BCF"},
            {Header : "S/N",				SaveName : "sn",			Type : "Text", Width : 160, Align : "center", EditLen : 100, FontColor : "#428BCF"},
            
            {Header : "Vintage",			SaveName : "vintage",		Type : "ComboEdit", Validation : 1, Width : 80, Align : "center", ComboText : "${vintageNms}", ComboCode : "${vintageCds}", FontColor : "#428BCF"},
            {Header : "Wafer Size",			SaveName : "wafer",			Type : "ComboEdit", Validation : 1, Width : 120, ComboText : "${waferNms}", ComboCode : "${waferCds}", FontColor : "#428BCF"},
            
            /*issue-request-No.687에 의해 컬럼추가(13 oct)*/     
            {Header : "Code",			SaveName : "sellCompEquipId", Type : "Text", MinWidth : 160, Align : "center", FontColor : "#428BCF"},/*issue-request-No.687에 의해 수정되오록 변경(12 oct)*/
            {Header : "Bid No",			SaveName : "bidNo", Type : "Text", MinWidth : 150, Align : "left", EditLen : 100, FontColor : "#428BCF"},/*issue-request-No.687에 의해 추가(12 oct)*/
            
            {Header : "Description",	SaveName : "description", Type : "Text", MinWidth : 150, Align : "left", FontColor : "#428BCF", EditLen : 1000},            
            {Header : "Low FMV",		SaveName : "equipLowMarketPrice", Type : "Float", Format : "Float", MinWidth : 110, Align : "right", FontColor : "#428BCF"},
            {Header : "High FMV",		SaveName : "equipHighMarketPrice", Type : "Float", Format : "Float", MinWidth : 110, Align : "right", FontColor : "#428BCF"},
            {Header : "Del",			SaveName : "delYn", Type : "DelCheck", Width : 50, Align : "center"},/*Select한건에대한Delete처리*/
            //--Hidden
            /*PDF기능 추가요청에 의해 추가(2017.1.3)*/
            {Header : "Sort Order", SaveName : "sortOrder", Type : "Int", Format : "Integer", Hidden : 1 },
            {Header : "unique object ID", SaveName : "oid", Type : "Text", Hidden : 1 },
            /* 속도개선을 위해 2개컬럼추가 (2017.1.17)*/
            {Header : "Sum equipLowMarketPrice", SaveName : "sumEquipLowMarketPrice", Type : "AutoSum", Format:"#,###.##", Width : 80, Align : "right", Hidden:1, Transaction : 0},
            {Header : "Sum equipHighMarketPrice", SaveName : "sumEquipHighMarketPrice", Type : "AutoSum", Format:"#,###.##", Width : 80, Align : "right", Hidden:1, Transaction : 0},
            /*PDF기능 추가요청에 의해 추가(2017.1.2)*/
            {Header : "Sum Amount", SaveName : "sumAmt", Type : "AutoSum", Format:"#,###.##", MinWidth : 80, Align : "right", Hidden:1, Transaction : 0},
            /*기능수정 #903에 의해 문서(Document_PDF_20161221.pptx) Page 16에 의해 제거됨(2016.12.26)*/
            {Header : "Category",		SaveName : "categoryGrp",	Type : "ComboEdit", Validation : 1, Align : "center", KeyField : 1, Width : 110, Edit : 1, ComboCode : "${strCateGrpCds}", ComboText : "${strCateGrpNms}", Hidden:1},
			{Header : "Part/Module Name",	SaveName : "partModuleNm",	Type : "Text", Width : 220, Align : "center", FontColor : "#428BCF", Edit:0, Hidden:1},
			{Header : "Configuration",	SaveName : "config", Type : "Text", Width : 150, Align : "left", EditLen : 1000, FontColor : "#428BCF", Hidden:1},/*issue-request-No.687에 의해 추가(12 oct)*/
			{Header : "Web",			SaveName : "webYn", Type : "CheckBox", Width : 50, Align : "center", TrueValue : "Y", FalseValue : "N", FontColor : "#428BCF", Hidden:1},
            {Header : "Featured",		SaveName : "featuredYn", Type : "CheckBox", Width : 100, Align : "center", TrueValue : "Y", FalseValue : "N", FontColor : "#428BCF", Hidden:1},
            {Header : "Payment ID",		SaveName : "paymentId",	Type : "Text", Width : 100, Align : "left", Edit : 0, Hidden:1},
            {Header : "Status",			SaveName : "status",	Type : "Status", Width : 30, Hidden : 1},
            /* 기능수정 #903 // */
            {Header : "Delivery Date",	SaveName : "deliDate", Type : "Date", Width : 150, Align : "center", Format : "Ymd", FontColor : "#428BCF", EditLen : 8, Hidden:1, Render:0},
            {Header : "Document ID",	SaveName : "docId", Type : "Text", Width : 100, Align : "left", Hidden : 1, Render:0},
            {Header : "Equip. Stage",	SaveName : "equipStage", Type : "Text", Width : 80, Align : "left", Hidden : 1, Render:0},
            {Header : "equipTxCnt",		SaveName : "equipTxCnt", Type : "Text", Width : 80, Align : "left", Hidden : 1, Render:0},
            {Header : "pre",			SaveName : "pre", Type : "Text", Width : 50, Hidden : 1, Render:0},/*relId관련Equip조회시사용.(Impl에서..)*/
            {Header : "Reference ID",	SaveName : "relId", Type : "Text", Width : 50, Hidden : 1, Render:0},/*relId없이 생성되는 경우.(Impl에서..)*/
            {Header : "Standard Maker",	SaveName : "standardMaker", Type : "Text", Width : 100, Align : "center", Hidden : 1, Render:0},
            {Header : "Standard Model",	SaveName : "standardModel", Type : "Text", Width : 100, Align : "center", Hidden : 1, Render:0},
            {Header : "pnc",			SaveName : "pnc", Type : "Text", Width : 100, Align : "center", Hidden : 1, Render:0},
            {Header : "opptId",			SaveName : "opptId", Type : "Text", Width : 70, Align : "left", Hidden : 1, Render:0},
            {Header : "wtbsId",			SaveName : "wtbsId", Type : "Text", Width : 130, Align : "left", Hidden : 1, Render:0},
            {Header : "quoteId",		SaveName : "quoteId", Type : "Text", Width : 130, Align : "left", Hidden : 1, Render:0},
            {Header : "poId",			SaveName : "poId", Type : "Text", Width : 130, Align : "left", Hidden : 1, Render:0},
            {Header : "preVerDocId",	SaveName : "preVerDocId", Type : "Text", Width : 130, Align : "left", Hidden : 1, Render:0},
            {Header : "deal status cd",	SaveName : "equipDealStatusCd", Type : "Text", Width : 130, Align : "left", Hidden : 1, Render:0},/*issue-request-No.685 : Deal Drop된 장비 대상으로 Tool Price 문서 생성 불가, 용역 문서 생성 가능 요청에 의해 기능추가*/
            {Header : "cntrId",			SaveName : "cntrId", Type : "Text", Width : 130, Align : "left", Hidden : 1, Render:0}];
        

        //시트 초기화
        IBS_InitSheet(mySheetEquip, initSheet);
        mySheetEquip.SetCountPosition(1);
        mySheetEquip.SetEditable(1);
        mySheetEquip.AllowEvent4CheckAll(0);	//전체체크시 속도개선
        
        //-- Payment Terms ------------------------------------------------

        initSheet = {};
        initSheet.Cfg = {SearchMode : smLazyLoad, Page : 50};
        initSheet.HeaderMode = {Sort : 1, ColMove : 1, HeaderCheckMode:1, ColResize : 1, HeaderCheck : 1};
        initSheet.Cols = [
			{Header : "No.", SaveName : "sortOrder", Type : "Int", Format : "Integer", MinWidth : 70, Edit:0, Hidden : 0 },			
            {Header : "%", SaveName : "pmtTermsValue", Type : "Int", format: "Integer", MinWidth : 80, Align : "center"},            
            {Header : "Amount", SaveName : "pmtTermsAmt", Type : "Float", PointCount : 2, Format:"#,###.##", MinWidth : 120, Align : "right", KeyField : 1, BackColor : "#EFEFEF"},
            {Header : "By", SaveName : "pmtTermsMethod", Type : "ComboEdit", Validation : 1, KeyField : 1, Align : "center", MinWidth : 120, ComboCode : "${pmtTermsMethodCds}", ComboText : "${pmtTermsMethodNms}"},
            {Header : "within ( ) Days", SaveName : "paytermPeriodVal", Type : "Int", Validation : 1, Align : "center", MinWidth : 120},
            {Header : "Business Process", SaveName : "paytermBizCd", Type : "ComboEdit", Validation : 1, Align : "center", MinWidth : 120, ComboCode : "${paytermBizCds}", ComboText : "${paytermBizNms}"},
            {Header : "Due Date", SaveName : "pmtDueDt", Type : "Date", MinWidth : 100, Align : "center", Format : "Ymd", EditLen : 8},
            {Header : "Remark", SaveName : "pmtTermsRemark", Type : "Text", MinWidth : 500, MultiLineText : 1, EnterMode : 1, EditLen : 4000},
            {Header : "Del", SaveName : "delete", Type : "DelCheck", MinWidth : 50},
            //-- Hidden
            {Header : "Sum Amount", SaveName : "sumAmt", Type : "AutoSum", Format:"#,###.##", MinWidth : 80, Align : "right", Hidden:1},
            {Header : "Status", SaveName : "status", Type : "Status", Width : 30, Hidden : 1},
            {Header : "Sel", SaveName : "sel", Type : "CheckBox", Width : 50, Align : "center", Hidden:1 },
            {Header : "Document ID", SaveName : "docId", Type : "Text", Width : 120, Align : "left", Hidden : 1},
            {Header : "Payterms ID", SaveName : "payTermsId", Type : "Text", Width : 80, Align : "right", Edit : 0, Hidden : 1},            
            {Header : "pre", SaveName : "pre", Type : "Text", Width : 50, Hidden : 1},/*relId관련 Payment조회시 사용.(Impl에서..)*/            
            {Header : "Day(s)/Week(s)/Month(s)", SaveName : "paytermPeriodDateType", Type : "ComboEdit", Validation : 1, Align : "center", Width : 120, ComboCode : "${paytermPeriodDateTypeCds}", ComboText : "${paytermPeriodDateTypeNms}", Hidden : 1, Render : 0},            
            {Header : "Type", SaveName : "pmtTermsRate", Type : "ComboEdit", Validation : 1, KeyField : 1, Align : "center", Width : 80, ComboCode : "${pmtTermsRateCds}", ComboText : "${pmtTermsRateNms}", Hidden : 1, Render : 0},
            {Header : "Period", SaveName : "paytermPeriodCd", Type : "ComboEdit", Validation : 1, Align : "center", Width : 120, ComboCode : "${paytermPeriodCds}", ComboText : "${paytermPeriodNms}", Hidden : 1, Render : 0}
        ];

        //시트 초기화
        IBS_InitSheet(mySheetPay, initSheet);
        mySheetPay.SetCountPosition(0);
        mySheetPay.FitColWidth();
        mySheetPay.SetEditable(1);

        //-- PDF ------------------------------------------------

        initSheet = {};
        initSheet.Cfg = {SearchMode : smLazyLoad, Page : 50};
        initSheet.HeaderMode = {Sort : 1, ColMove : 1, ColResize : 1, HeaderCheck : 1};
        initSheet.Cols = [                          
                          {Header : "No.", SaveName : "sortOrder", Type : "Int", Format : "Integer", MinWidth:70, Edit:0, Hidden:0 },
                          {Header : "Description", SaveName : "pdfDesc", Type : "Text", MinWidth : 320, Align : "left", KeyField : 1, MultiLineText : 1, Wrap:1, EnterMode : 1},
                          {Header : "Unit Price",		SaveName : "unitPrice", Type : "Float", PointCount : 2, Format : "#,###.##", MinWidth : 130, Align : "right", FontColor : "#428BCF"},
                          {Header : "Qty",		SaveName : "qty", Type : "Int", Format : "Integer", MinWidth : 130, Align : "right", FontColor : "#428BCF"},
                          {Header : "Amount", SaveName : "amt", Type : "Float", PointCount : 2, Format : "#,###.##", MinWidth : 80, Align : "right", KeyField : 1},
                          {Header : "Del", SaveName : "delete", Type : "DelCheck", MinWidth : 50},
                          //-- Hidden
                          {Header : "Status", SaveName : "status", Type : "Status", MinWidth : 30, Hidden : 1},
                          {Header : "pdfSeq", SaveName : "pdfSeq", Type : "Text", MinWidth : 50, Align : "right", Edit: 0, Hidden:1},
                          {Header : "Sum Amount", SaveName : "sumAmt", Type : "AutoSum", Format:"#,###.##", MinWidth : 80, Align : "right", Hidden:1},                         
                          {Header : "Doc ID", SaveName : "docId", Type : "Text", Hidden : 1, Render : 0}
                      ];

        //시트 초기화
        IBS_InitSheet(mySheetPdf, initSheet);

        mySheetPdf.SetCountPosition(0);
        mySheetPdf.FitColWidth();
        mySheetPdf.SetEditable(1);
      	//편집모드시 화살표키(상,하,좌,우)에 대한 셀의 포커스 이동 동작 : 셀 상하,좌우 이동 불가
        mySheetPdf.SetEditArrowBehavior(0);
    }
    
    //장비저장후 Callback
    var viewPDF = false;
    function equipSave_successCallback(){
    	if (viewPDF){
    		viewPDF = false;
    		openPackagePDF();
    	}
    }

    /*------------------------------------------------------------------------
     *  Event : doAction(str)
     *  Desc. : 실행
     *------------------------------------------------------------------------*/
    function doAction(str, next) {
        switch (str) {
            case "SearchStage":
                //------------------------------------------
                // Deal Stage Data Search
                //------------------------------------------
                var param = {url : "SP0300MStageSearch.do", subparam : FormQueryStringEnc(document.Frm) //폼객체 안에 내용을 QueryString으로 바꾼다.
                , sheet : ["mySheet"]};
                DataSearch(param);
                
                break;

            case "Search1":
                //------------------------------------------
                // Deal List Relation
                //------------------------------------------
                var param = "";
                parent.func_maincall("SP0510M.do", "Offer/PO/Cont/Inv ", "", "Offer/PO/Cont/Inv ", param);
                break;
                
            case "SearchTree":
                //------------------------------------------
                // Tree 조회...
                //------------------------------------------
                //mySheetTree.SetMergeSheet(msHeaderOnly);
                var subParam = 'paramId=' + $('#docId').val();
                var param = {url : "commonSearchTree.do", subparam : subParam, sheet : ["mySheetTree"]};
                DataSearch(param);
                break;
                
            case "AutoPo":
                //------------------------------------------
                // autoPo ( QUOTE + QUOTE APPROVAL + PO )
                //------------------------------------------
                //alert("autoAppYn -> "+autoAppYn);
                autoAppYn = "Y";
                doAction("SaveStage");
                break;

            case "SaveStage":
                //------------------------------------------
                // Create Deal Stage Data
                //------------------------------------------

                if (!dateValidationCheck()) {
                    break;
                }
                viewPDF = false;
                if (next){
                	viewPDF = true;
                	lfn_viewPDFPopup();	//Blocking되지 않도록 파업 미리 띄우기
                }
                Frm_Validation(); //-- Stage Data Check.( Result == "Success" )
                if (Result == "Success") {
                    Equip_Validation();
                } //-- Equip Data Check.( Result == "Success" )
                if (Result == "Success") {
                    Pay_Validation();
                } //-- Pay Data Check.( Result == "Success" )
                if (Result == "Success") {
                    payTermsTotal();
                } //-- Payment Terms의 총합 체크
                if (Result == "Success"){
                	PDF_Validation();
                }
                if (Result != "Success"){
                    if (next){
                    	viewPDF = false;
             	    	if (popPDFView){
             	    		popPDFView.close();	//검증실패시 닫기(Blocking Popup을 피하려면 미리 띄워야만 동작함으로 닫을지라도 미리 띄워야 함)
             	    	}
                    }
                	break;
                }
                isSavedStage = false;                
            	
                var oldDocId = document.getElementById("docId").value;

                if (Result == "Success") {
                	
                    unbindLink.start();
                    $.ajax({type : 'POST', url : "SP0300MStageSave.do", data : FormQueryStringEnc(document.Frm), dataType : "json", async : true, success : function(data) {
                        var result = data.split("/");
                        
                        unbindLink.end();
                        if (next){	//다음작업이 있으면 결과alert안띄우도록 처리
                        	isSavedAlert = false;
                        }
                        
                        if (typeof result[1] == "undefined") {	//예외없이 정상저장이면
                            //-- SUCCESS
                            document.getElementById("docId").value = data; //-- Document ID Set.
                            //-- iFrame Reload.
                            //결재IFrame없애며 주석처리(2017.1.10)
                            //$('#frame_approval').prop("src", "${pageContext.request.contextPath}/approval.do?doc_id=" + document.getElementById('docId').value);
                        	
                            if ($('#doc_id').val() != $('#docId').val()){
                            	$('#doc_id').val($('#docId').val());
                            	initApproval();
                            }

                            //-----------------------
                            SaveEquipResult = "Success";
                            SavePayResult = "Success";                            

                            //복잡한 비교개선
    						doAction("SavePdf");
    						doAction("SavePdfCol");
    						doAction("SaveEquip");	//sync save
    						doAction("SavePay");    						
    						
                        	if (next){
                            	next();
                            }
    						
    						if (SaveEquipResult == "Success" && SavePayResult == "Success") {
    						    SaveEndMessage();
    						}
                            
                        } else {

                            //-- ERROR

                            unbindLink.end();
                            document.getElementById("docId").value = result[0]; //-- Document ID Set.
                            alert("<spring:message code="message.error"/> : " + result[1]);
                        }
                    }, error : function() {

                    	unbindLink.end();
                        alert("<spring:message code="message.error"/>");
                    }});
                    
                    isSavedStage = true;
                }
                break;

            case "SearchEquip":
                //------------------------------------------
                // EquipMent Data Search
                //------------------------------------------
            	if (sevingEquip){	//저장중 조회막기 위함
                	break;
                }
                unbindLink.start();
                var param = {url : "SP0300MSearchEquip.do", subparam : FormQueryStringEnc(document.Frm) //폼객체 안에 내용을 QueryString으로 바꾼다.
                , sheet : ["mySheetEquip"]};
                DataSearch(param);
                break;

            case "AddEquip":
                //------------------------------------------
                // EquipMent Add.
                //------------------------------------------
                var newRow = mySheetEquip.DataInsert(0);
                mySheetEquip.SetCellValue(newRow, "docId", "New");
                mySheetEquip.SetCellValue(newRow, "eId", "New");
                mySheetEquip.SetCellValue(newRow, "equipTxCnt", "1");
                mySheetEquip.SetCellValue(newRow, "categoryGrp", "");
                mySheetEquip.SetCellValue(newRow, "subject", "");
                mySheetEquip.SetCellValue(newRow, "wafer", "");
                mySheetEquip.SetCellValue(newRow, "webYn", "Y");
                mySheetEquip.SetCellValue(newRow, "featuredYn", "Y");
                mySheetEquip.SetCellValue(newRow, "m2", 0);
                mySheetEquip.SetCellValue(newRow, "cbm", 0);
                break;

            case "SaveEquip":            	
                //------------------------------------------
                // Equipment Save
                //------------------------------------------
                if (!mySheetEquip.IsDataModified()) {

                	unbindLink.end();
                	break;
                }
                
                var equipCnt = mySheetEquip.LastRow() - 1;
                for (var r = 1; r <= equipCnt; r++) {
                    //-- 신규등록시, Document ID Set.
                    if (mySheetEquip.GetCellValue(r, "docId") == "New") {
                        mySheetEquip.SetCellValue(r, "docId", document.getElementById("docId").value);
                    }
                    //-- Standard Maker/Model 을 Temp에  Set.
                    if (mySheetEquip.GetCellValue(r, "standardModel") != "") {
                        if (mySheetEquip.GetCellValue(r, "maker") == "") {
                            mySheetEquip.SetCellValue(r, "maker", mySheetEquip.GetCellValue(r, "makerNm"));
                        }
                        if (mySheetEquip.GetCellValue(r, "model") == "") {
                            mySheetEquip.SetCellValue(r, "model", mySheetEquip.GetCellValue(r, "modelNm"));
                        }
                    }
                    //-- 조회시, 가져온 equipStage와 DealStage가 다르면 Update.
                    //-- Equip 에 Stage Update..
                    //이부분 제거(Backend에서 사용안하고 있다!, 저장속도개선효과)(2017.1.12)
					//mySheetEquip.SetCellValue(r, "equipStage", document.getElementById('docTitle').value);

                    //-----------------------------------------------
                    //-- Temp 입력안된 경우...체크...Test...
                    if (mySheetEquip.GetCellValue(r, "maker") == "") {
                        mySheetEquip.SetCellValue(r, "maker", 'X');
                    }
                    if (mySheetEquip.GetCellValue(r, "model") == "") {
                        mySheetEquip.SetCellValue(r, "model", 'X');
                    }
                    //-----------------------------------------------
                    //-- relId없이 생성되는 경우.(Impl에서..)
                    //이부분 제거(Backend에서 사용안하고 있다!, 저장속도개선효과)(2017.1.12)
                    //mySheetEquip.SetCellValue(r, "relId", document.getElementById("relId").value);
                }

                var param = {url : "SP0300MEquipSave.do", subparam : FormQueryStringEnc(document.Frm) //폼객체 안에 내용을 QueryString으로 바꾼다.
                , sheet : ["mySheetEquip"], quest : false, sync : true};
                sevingEquip = true;	//async상태이므로 중복조회 안하기 위해 설정함
                DataSave(param);
                
                break;

            case "SearchPay":
                //------------------------------------------
                // Payment Terms Data Search
                //------------------------------------------

                var param = {url : "SP0300MSearchPayTerms.do", subparam : FormQueryStringEnc(document.Frm) //폼객체 안에 내용을 QueryString으로 바꾼다.
                , sheet : ["mySheetPay"]};
                DataSearch(param);
                break;

            case "AddPay":
                //------------------------------------------
                // Payment Terms Add.
                //------------------------------------------
                var newRow = mySheetPay.DataInsert(-1);
                mySheetPay.SetCellValue(newRow, "docId", "New");
				var info = {Edit : 1, Type : "Float", PointCount:2, Format:"#,###.##"};
            	
                if ($('#currency').val().indexOf('KRW') > -1){
                	info.Format = "#,###";
                	info.PointCount = 0;
                	info.Type = "Int";
                }
                mySheetPay.InitCellProperty(newRow, "pmtTermsAmt", info);
            	mySheetPay.SetCellEditable(newRow, "pmtTermsAmt", info.Edit);
            	mySheetPay.SetCellBackColor(newRow, "pmtTermsAmt", "#FFFFFF");
            	
            	maxId4Pay = mySheetPay.LastRow()-1;            	       	
            	mySheetPay.SetCellValue(newRow, "sortOrder", maxId4Pay++);
            	
                break;

            case "SavePay":
            	if (!mySheetPay.IsDataModified()) break;
                //------------------------------------------
                // Payment Terms Save
                //------------------------------------------                
                var value = "";
                var cnt = 0;
                for (var r = 1; r <= mySheetPay.LastRow(); r++) {
                	//신규문서일경우 초기화
                    if (mySheetPay.GetCellValue(r, "docId") == "New") {
                        mySheetPay.SetCellValue(r, "docId", document.getElementById("docId").value);
                        mySheetPay.SetCellValue(r, "payTermsId", "");	//모두 null이어야 정상 등록됨
                    }
                    value = mySheetPay.GetCellValue(r, "pmtTermsValue");
                    if (value == ""){
                    	savingPay = true;
                    	mySheetPay.SetCellValue(r, "pmtTermsValue", "0");	//0이면 안보이게 해달라는 요청에 의해 Percent지웠던 것에 기본값 0을 넣어준다(저장시 필수)
                    }
                    if (mySheetPay.GetCellValue(r, "status") != 'D'){
                    	mySheetPay.SetCellValue(r, "sortOrder", ++cnt);	//현재상태로 sort order재설정
                    }
                }

                var param = {url : "SP0300MPayTermsSave.do", subparam : FormQueryStringEnc(document.Frm) //폼객체 안에 내용을 QueryString으로 바꾼다.
                , sheet : ["mySheetPay"], quest : false};
                DataSave(param);

                //doAction("SearchPay");
                break;

            case "VisibleEquip":
                //------------------------------------------
                // Equipment List Visible
                //------------------------------------------
                view('EquipInfo');
                break;

            case "VisiblePay":
                //------------------------------------------
                // Equipment List Visible
                //------------------------------------------
                view('PaymentInfo');
                break;

            case "SelEquip":
                //----------------------------------
                //-- Equipment List (Multi Select) PopUp
                //----------------------------------
                openPopup('eId');
                break;

            case "CreatePayment":
                //------------------------------------------
                // Payment Relation(Ben)
                //------------------------------------------
                //-- Payment 등록시, 결재여부 체크

                if (mySheet.GetCellValue(1, "appMMYn") == "Y") {

                    //--Ben---------------------------------------------------------------
                    if (mySheetEquip.CheckedRows("sel") > 0) { // 장비가 선택되어야 payment 생성 가능
                        var paramEid = ""; // 선택된 EID만 추출
                        var paramEquipTxCnt = "";
                        var pararmSubjectCd = "";
                        var checkCnt = 0;

                        //--Add.-----------------------------------------
                        //-- Payment가 기생성된 경우는 다시 생성불가.
                        var existPayment = "N";
                        for (var i = 1; i < mySheetEquip.RowCount() + 1; i++) {
                            if (mySheetEquip.GetCellValue(i, "sel") == "1") {
                                if (mySheetEquip.GetCellValue(i, "paymentId") != "") {
                                    alert("<spring:message code="message.save.fail.existpayment"/>");
                                    existPayment = "Y";
                                    break;
                                }
                            }
                        }
                        //--Add.-----------------------------------------
                        if (existPayment == "N") {

                            for (var i = 1; i < mySheetEquip.RowCount() + 1; i++) {
                                if (mySheetEquip.GetCellValue(i, "sel") == "1") {
                                    if (paramEid == "") {
                                        paramEid = "'" + mySheetEquip.GetCellValue(i, "eId") + "'";
                                        paramEquipTxCnt = "'" + mySheetEquip.GetCellValue(i, "equipTxCnt") + "'";
                                        pararmSubjectCd = "'" + mySheetEquip.GetCellValue(i, "subject") + "'";
                                    } else {
                                        paramEid += ",'" + mySheetEquip.GetCellValue(i, "eId") + "'";
                                        paramEquipTxCnt += ",'" + mySheetEquip.GetCellValue(i, "equipTxCnt") + "'";
                                        pararmSubjectCd += ",'" + mySheetEquip.GetCellValue(i, "subject") + "'";
                                    }
                                    if (mySheetEquip.GetCellValue(i, "subject") == "TOOL_PRICE") {
                                        checkCnt++;
                                    }
                                }
                            }

                            var tempCreateFlag = "";
                            if ("QUOTE|INV".indexOf($("#docTitle").val()) > -1) { // Quote, Invoice에서 payment 생성시는 subject - TOOL_PRICE 제외
                                if (checkCnt > 0) {
                                    alert("<spring:message code="message.sp.quotepaymenttool"/>");
                                    return;
                                } else {
                                    tempCreateFlag = "N";
                                }
                            } else { // 나머지는 모든 subject로 payment 생성 가능
                                tempCreateFlag = "Y";
                            }

                            var param = "&createFlag=" + tempCreateFlag + "&paramDocId=" + docIdOrg + "&paramEid=" + paramEid + "&paramEquipTxCnt=" + paramEquipTxCnt + "&subjectCd=" + pararmSubjectCd;
                            parent.func_maincall("PA0200M.do", "Payment > Create", "", "Payment", param);
                        }

                    } else { // 장비가 선택되지 않았을 경우 alert 처리
                        alert("<spring:message code="message.save.fail.noselectEquip"/>");
                        return;
                    }
                    //--Ben---------------------------------------------------------------
                } else {
                    alert("<spring:message code="message.save.fail.approval"/>");
                }
                break;

            case "CreateShipment":
                //------------------------------------------
                // Shipment Relation(Ben)
                //------------------------------------------
                //-- Shipment 등록시, 결재여부 체크
                if (mySheet.GetCellValue(1, "appMMYn") == "Y") {

                    //--Ben---------------------------------------------------------------
                    if (mySheetEquip.CheckedRows("sel") > 0) { // 장비가 선택되어야 payment 생성 가능

                        if (document.getElementById('docTitle').value == "PO"
                        	 ||	document.getElementById('docTitle').value == "CNTR") {
                            //-- Shipment Create.
                            var paramEid = "";
                            var paramEquipTxCnt = "";
                            for (var i = 1; i < mySheetEquip.RowCount() + 1; i++) {
                                if (mySheetEquip.GetCellValue(i, "sel") == "1") {
                                    if (paramEid == "") {
                                        paramEid = "'" + mySheetEquip.GetCellValue(i, "eId") + "'";
                                        paramEquipTxCnt = "'" + mySheetEquip.GetCellValue(i, "equipTxCnt") + "'";
                                    } else {
                                        paramEid += ",'" + mySheetEquip.GetCellValue(i, "eId") + "'";
                                        paramEquipTxCnt += ",'" + mySheetEquip.GetCellValue(i, "equipTxCnt") + "'";
                                    }
                                }
                            }
                            var param = "&createFlag=I&paramDocId=" + docIdOrg + "&paramEid=" + paramEid + "&paramEquipTxCnt=" + paramEquipTxCnt;
                            parent.func_maincall("LO0210M.do", "Logistics > Move In & Out", "LO0210M", "Move In & Out", param);

                        } else {
                            //-- PO만 Shipment Create.
                            alert("<spring:message code="message.save.fail.onlypo"/>");
                        }

                    } else {
                        //-- 장비가 있어야 Shipment Create.
                        alert("<spring:message code="message.save.fail.noselectEquip"/>");
                    }
                    //--Ben---------------------------------------------------------------
                } else {
                    alert("<spring:message code="message.save.fail.approval"/>");
                }
                break;

            case "RefurbSource":
                //------------------------------------------
                // Refurb Source PopUp
                //------------------------------------------
                openPopup('RefurbSource');
                break;

            case "PackagePDF":
                //------------------------------------------
                // packagePDF
                //------------------------------------------

                // pdf 와 동일 조건 , 문서 조건들을 체크박스 선택한 값만 pdf 에서 보여주기 위해 변수들을 넘긴다.
                //chk_warrTerm  chk_warrLabor chk_warrPart chk_priceTerm  chk_packType  chk_packRes  chk_ship  chk_bank chk_validity chk_delivery chk_remark

/*                 if ($("#docId").val() == "") {
                    alert("<spring:message code="message.sp.savedocaction"/>");

                    break;
                } */

                if (showMode === mode.lookAt.EDIT){ //수정모드일때만 검증수행하도록 변경(PDF가 화면에 들어오면서 이조건이 필요하게됨, 2017.1.24)
                    PDF_ViewValidation();
                    if (Result != "Success") {
                        break;
                    }
                }
                
                //저장버튼이 활성화 되어 있으면 저장
                if (isViewSaveButton && showMode === mode.lookAt.EDIT){//수정모드일때만 검증수행하도록 변경(PDF가 화면에 들어오면서 이조건이 필요하게됨, 2017.1.24)
                	doAction("SaveStage", openPackagePDF);
                }
                else{
                	openPackagePDF();
                }
                
                break;
            case "DocCopy":
            case "VersionUp":

                var prvDocId = $("#docId").val();
                
                $('#attaGrpId').val('');
              	//결재IFrame없애며 주석처리(2017.1.10)
                //$('#frame_approval').prop("src", "${pageContext.request.contextPath}/approval.do?doc_id=");
              	$('#doc_id').val('');
              	initApproval();
                
              	//첨부조회
                doAction("searchAttach");

                $("#docId").val("");
                $("#customerDocId").val("");

                for (var r = 1; r <= mySheetEquip.LastRow() - 1; r++) {
                    mySheetEquip.SetCellValue(r, "no", "New");
                    mySheetEquip.SetCellValue(r, "paymentId", "");
                    mySheetEquip.SetCellValue(r, "docId", "New");
                }

                for (var r = 1; r <= mySheetPay.LastRow() - 1; r++) {
                    mySheetPay.SetCellValue(r, "docId", "New");
                }

                $("#docButton").show();
				/*Button*/                
                $("#copyButton").hide();
                $("#versionUpButton").hide();

                $("#opperType").attr("disabled",false);
                $("#poType").attr("disabled",false);
                $("#contractType").attr("disabled",false);
                $("#invoiceType").attr("disabled",false);

                if(str=="DocCopy") {
                    
	                $("#equipButton").show();
	                $("#paymentButton").show();
	                $("#preVerDocId").val("");
	                
                } else if(str=="VersionUp") {
                    
	                $("#equipButton").hide();
	                $("#paymentButton").hide();
	                
	                /* 수정 불가 필드*/
	                $("#buyCompId").attr("disabled",false);
	                $("#docBuyCompNm").attr("disabled",true);
	                $("#fromPicPersonId").attr("disabled",true);
	                $("#docFromPicPersonNm").attr("disabled",true);
	                $("#sellCompId").attr("disabled",true);
	                $("#docSellCompNm").attr("disabled",true);
	                $("#picPersonId").attr("disabled",true);
	                $("#docPicPersonNm").attr("disabled",true);
	                $("#currency").attr("disabled",true);
	   
	                /*Equipment list*/
	                mySheetEquip.SetColEditable("unitPrice", false);
	                mySheetEquip.SetColEditable("subject", false);
	                /*Payment Term*/
	                mySheetPay.SetEditable(false);
	                mySheetPdf.SetEditable(false);	                
	                
	                $("#preVerDocId").val(prvDocId);

                    toogleVersionUpControl(true);
                    
                }
                break;
                
            case "AddPdf":
                //------------------------------------------
                // PDF Add.
                //------------------------------------------
				var newRow = mySheetPdf.DataInsert(-1);
                mySheetPdf.SetCellValue(newRow, "docId", "New");
                
				var info = {Edit : 1, Type : "Float", PointCount:2, Format:"#,###.##"};
            	
                if ($('#currency').val().indexOf('KRW') > -1){
                	info.Format = "#,###";
                	info.PointCount = 0;
                	info.Type = "Int";
                }
                //mySheetPdf.SetCellValue(newRow, "no", mySheetPdf.RowCount());
                mySheetPdf.InitCellProperty(newRow, "amt", info);
            	mySheetPdf.SetCellEditable(newRow, "amt", info.Edit);
            	mySheetPdf.SetCellBackColor(newRow, "amt", "#FFFFFF");
            	
            	maxId4Pdf = mySheetPdf.LastRow()-1;
            	mySheetPdf.SetCellValue(newRow, "sortOrder", maxId4Pdf++);
                
                break;
                
            case "SearchPdf":
                //------------------------------------------
                // PDF Search
                //------------------------------------------
                var param = {url : "SP0300MPdfSearch.do", subparam : FormQueryStringEnc(document.Frm) //폼객체 안에 내용을 QueryString으로 바꾼다.
                , sheet : ["mySheetPdf"]};
                DataSearch(param);
                break;

            case "SavePdf":
                if (!mySheetPdf.IsDataModified()){ break; }
                //------------------------------------------
                // PDF Save
                //------------------------------------------
            
                var cnt = 0;
                for (var r = 1; r <= mySheetPdf.LastRow(); r++) {
                    //-- 신규등록시, Document ID Set.
                    //if (mySheetPdf.GetCellValue(r, "docId") == "New") {
                        mySheetPdf.SetCellValue(r, "docId", document.getElementById("docId").value);
                    //}
                    if (mySheetPdf.GetCellValue(r, "unitPrice") == "") {
                        mySheetPdf.SetCellValue(r, "unitPrice", 0);
                    }
                    if (mySheetPdf.GetCellValue(r, "status") != 'D'){
                    	mySheetPdf.SetCellValue(r, "sortOrder", ++cnt);	//현재상태로 sort order재설정
                    }
                }

                var param = {url : "SP0300MPdfUpdate.do", subparam : FormQueryStringEnc(document.Frm) //폼객체 안에 내용을 QueryString으로 바꾼다.
                , sheet : ["mySheetPdf"], quest : false};
                DataSave(param);
                
                break;
                
            case "SearchPdfCol":
            	//------------------------------------------
                // PDF Column Mapper Search
                //------------------------------------------
                
                if ($('#docId').val() == ''){ break; }
                
                $.ajax({
					type : 'POST',
					url : 'SP0300MPdfColSearch.do',
					data : FormQueryStringEnc(document.Frm),
					dataType : "json",
					async : true,
					success : function(data) {
								
						if (data.Data){
							//초기화
							$('[name=pdfColVal]').each(function(idx, e){
								$(e).prop('checked', false);
							});
							//check처리한다
							$(data.Data).each(function(idx, e){
								$("input[name=pdfColVal][value='" +e.typeVal+ "']").prop("checked", true);
							});
						}
					},
					error : function(e) {
						alert('<spring:message code="message.error"/>');
					}
				});
                
            	break;

            case "SavePdfCol":
            	//------------------------------------------
                // PDF Column Mapper Save
                //------------------------------------------
                var pdfColValList = '';
                $('[name=pdfColVal]').each(function(idx, e){
					if ($(e).is(':checked')){
						pdfColValList += ',' + e.value + ':0';
					}
					else{
						pdfColValList += ',' + e.value + ':1';
					}                
				});
            	
                $.ajax({
					type : 'POST',
					url : 'SP0300MPdfColUpdate.do',
					data : FormQueryStringEnc(document.Frm) + '&pdfColValList=' + pdfColValList.substr(1),
					dataType : "json",
					async : true,
					success : function(data) {
						
						if (data){			
              				doAction("SearchPdfCol");	
						}
					},
					error : function(e) {
						alert('<spring:message code="message.error"/>');
					}
				});
				
            	break;
            /*[추가-시작](10 jan 2017)*/
            case "searchAttach":
            	if ($('#attaGrpId').val() == ''){
            		mySheetAttachFile.LoadSearchData({Data:[[]]});	//결과 비움
            	}
            	else{
            		setAttaGrpId($("#attaGrpId").val());
            		setFileAttUrl("${pageContext.request.contextPath}/innorix/example/innoex/upload.html?atta_grp_id="+F_attaGrpId+"&serverUrl=<%=session.getAttribute("serverUrl")%>&irx_sess_id=<%=session.getId()%>&callback=");
            		doAction_F("F_search");
            	}
                break;
            case "Attachments":	//첨부버튼 클릭시
            
            	if ($('#attaGrpId').val() == ''){
            		var newAttaGrpId = getAttaGrpId();            		
            		setAttaGrpId(newAttaGrpId);
            	}
            	else{
            		setAttaGrpId($("#attaGrpId").val());
            	}
            	
            	setFileAttUrl("${pageContext.request.contextPath}/innorix/example/innoex/upload.html?atta_grp_id="+F_attaGrpId+"&serverUrl=<%=session.getAttribute("serverUrl")%>&irx_sess_id=<%=session.getId()%>&callback=lfn_attachAfter" +postAttaUrl);
            	
                doAction_F("F_Attachments");
                
                break;
                
            case "Delete_F":
            	
            	//선택한 것중 결재전에 추가한 존재하면?
            	var isDeleteAttach = true;
				if (custSendAttaYn == 'Y'){
					var dRows = mySheetAttachFile.FindCheckedRow("del",{ReturnArray:1});
					
					$(dRows).each(function(i,e){
						if (isDeleteAttach && mySheetAttachFile.GetCellValue(e, 'custSendAttaYn') != 'Y'){
							alert('Attachments can not be deleted prior to approval!');//결재 이전에 첨부는 삭제할 수 없다
							isDeleteAttach = false;
						}
					});
            	}
				if (isDeleteAttach){
					doAction_F("F_Delete");	
				}
                
                
                break;                
            /*[추가-끝]*/
            
            case "FullHeightByEquip":	//장비최대화클릭시(22 jan 2017)
            	           	 
            	sheetHeight = !sheetHeight ? $('#DIV_mySheetEquip').height() : sheetHeight;	//set default height(최초 장비최대화 클릭여부의 의미로도 쓰임)
           	 
                //장비최대화모드가 Equip이 아닐때? StageSearch후에 조회되어야 함
            	equipMode = equipMode === mode.full.EQUIP ? mode.full.NORMAL : mode.full.EQUIP;	//장비최대화모드(toggle)

				if (equipMode === mode.full.EQUIP){
					$(".notEquipComponent").hide();                    
				} else {
					$(".notEquipComponent").show();
				}
                lfn_ResizeSheet();
           	 
           	 break;
           	 
            case "Modify":	//수정모드버튼 클릭(24 jan 2017)
            	//조회모드가 최초에 View이었다가 Edit로 최초 바뀔때!(그 외에는 StageSearch후:mySheet_OnSearchEnd 에서만)
            	if (firstView){
            		doAction("SearchEquip");
            	}
            
            	//조회모드가 View가 아닐때? StageSearch후에 조회되어야 함
            	showMode = showMode === mode.lookAt.EDIT ? mode.lookAt.VIEW : mode.lookAt.EDIT;	//수정모드(toggle)
            	
                $(".PDFComponent1").toggle("fast");   //PDF View toggle(PDF가 보여질떄는 먼저그려져야 장비최대화가 화면에 Full로 채워진다)

            	if (equipMode === mode.full.EQUIP){	//장비최대화일때
            		$(".equipComponent").toggle("fast", function(e){
                        //높이작은화면에서 View -> Edit모드 + 장비최대화 후에 View모드로 이동하고 큰화면에서 Edit모드로 클릭시 화면에 채워지지 않는 문제처리를 위해 수행
                        if (showMode === mode.lookAt.EDIT){
                            lfn_ResizeSheet();                            
                        }
                    });
                    
            	}else{
            		$(".notEquipComponent,.equipComponent").toggle("fast");
            	}
            	
            	break;
        }
    }
	
	//define mode dictionary(24 jan 2017)
    var sheetHeight = 0;	//장비Sheet 초기높이값
	const mode = {lookAt:{VIEW:'lookAt.VIEW', EDIT:'LookAt.EDIT'}, full:{NORMAL:'full.NORMAL', EQUIP:'full.EQUIP'}};	
	var showMode = mode.lookAt.VIEW;	//화면모드
	var equipMode = mode.full.NORMAL;	//장비최대화모드
     
    //Ajax Blocking회피하기위해 Interval처리
    var myVar;  //tiemer flag Object
 	var excutedCnt = 0; //실행된 수
    var isSavedStage = false;   //Header저장종료여부
    var isSavedAlert = true;
 	function stopInitTimer() { 		
 	   clearInterval(myVar);
 	   isSavedStage = false;
 	}	
 	function initTimer(){
 		if (excutedCnt > 400){	//timeout:200,000msec : 무한기다림 회피
 			stopInitTimer();
 		} else if (isSavedStage){
 			stopInitTimer();	//Timer소멸
 			//call PDF Popup
            openPackagePDF();
            isSavedStage = false;
 		}		
 		excutedCnt++;
 	}
 	
 	//화면에서 보여주고 있는지 여부.ILib:(24 jan 2017)
 	function isView(e){
        var e = e || arguments;
        console.log('argument type:' +(typeof e));
 		if (e){
 			if (typeof e === 'string'){
 				e = $(e);
 			} else if(typeof e === 'object'){
 				//e = e;
                //console.log(e);
 			}
 			if ($(e).css('display') != undefined && $(e).css('display') != 'none'){
 				return true;
 			}
 		}
 		return false;
 	}
 	
 	//PDF팝업띄우기, (Blocking Popup회피기능) (11 jan 2017)
 	var popPDFView;
 	function lfn_viewPDFPopup(sendToPDF, param) {
 	    var url = '';
 	    if(param){
 	        url = url +param;
 	    }
 	    var data = {};
 	    
 	    var w = 850;
 	    var h = 730;
 	    var defaultOption = "toolbar=no, directories=no, status=no, scrollbars=yes, resizable=yes";
 	    var LeftPosition = (screen.width - w) / 2 ;
 	    var TopPosition = (screen.height - h) / 2 ;
 	    LeftPosition = LeftPosition < 0 ? 0 : LeftPosition;
 	    TopPosition = TopPosition < 0 ? 0 : TopPosition;
 	    
 	    if (popPDFView == null || popPDFView.closed){
 	    	popPDFView = window.open("./view/sp/loading.html", "lfn_viewPDFPopup", defaultOption + ", top="+TopPosition+", left="+LeftPosition+", width="+w+", height="+h);
 		}
 		else{
 			popPDFView.focus();
 		}
 	    
 	    if (sendToPDF){
 	    	if (popPDFView){
 	    		popPDFView.focus();
 	    	}
 			var frm = $('<form/>');
 			frm.attr('target', 'lfn_viewPDFPopup')
 			.attr('method', 'post')
 			.attr('action', url);
 			
 			for (key in data){
 				if (key) frm.append($("<input type='hidden' name='"+key+"' value='" +data[key]+ "'>"));
 			}
 			
 			frm.appendTo('body')
 			.submit();
 			
 	    }else{

 	    }
 		if (popPDFView != null){
			popPDFView.onclose = function(){
	 	    	popPDFView = null;
	 	    };
 		}
 	    
 	    return popPDFView;
 	}
 	//첨부후에 callback(10 jan 2017)
 	function lfn_attachAfter(result){
 		//첨부가 된적이 없으면 Header에 등록한다!
 		if ($('#docId').val() != '' && attaGrpIdOrg == ''){
 			attaGrpIdOrg = $('#attaGrpId').val();
 			var params = {docId:$('#docId').val(), attaGrpId:attaGrpIdOrg};
        	ComCallAjaxUrl('SP0300MSaveAtt.do', params, function(data){}); 
 		} 		
 	}
 	
     //PackagePDF화면 호출(11 jan 2017)
    function openPackagePDF(){
	     var chk_warrTerm = document.Frm.chk_warrTerm.checked == true ? "1" : "0";
	     var chk_warrLabor = document.Frm.chk_warrLabor.checked == true ? "1" : "0";
	     var chk_warrPart = document.Frm.chk_warrPart.checked == true ? "1" : "0";
	     var chk_priceTerm = document.Frm.chk_priceTerm.checked == true ? "1" : "0";
	     var chk_packType = document.Frm.chk_packType.checked == true ? "1" : "0";
	     var chk_packRes = document.Frm.chk_packRes.checked == true ? "1" : "0";
	     var chk_ship = document.Frm.chk_ship.checked == true ? "1" : "0";
	     var chk_bank = document.Frm.chk_bank.checked == true ? "1" : "0";
	     var chk_validity = document.Frm.chk_validity.checked == true ? "1" : "0";
	     var chk_delivery = document.Frm.chk_delivery.checked == true ? "1" : "0";
	     var chk_remark = document.Frm.chk_remark.checked == true ? "1" : "0";
	
	     var varDocTitle = mySheet.GetCellValue(1, "docTitle"); // QUOTE,PO,INV
	     var varDealType = mySheet.GetCellValue(1, "dealType"); // BUY,SELL
	     
	     var varCompId = "";
	     
	     if (varDealType == "BUY"){
	     	varCompId = $("#buyCompId").val();
	     }else{
	     	varCompId = $("#sellCompId").val();
	     }
	     
	     var url = 'downPDFNew.do?docId='+$("#docId").val()+'&docTitle=' + varDocTitle + '&dealType=' + varDealType + '&chk_warrTerm=' + chk_warrTerm + '&chk_warrLabor=' + chk_warrLabor + '&chk_warrPart=' + chk_warrPart + '&chk_priceTerm=' + chk_priceTerm + '&chk_packType=' + chk_packType + '&chk_packRes=' + chk_packRes + '&chk_ship=' + chk_ship + '&chk_bank=' + chk_bank + '&chk_validity=' + chk_validity + '&chk_delivery=' + chk_delivery + '&chk_remark=' + chk_remark + '&sg_Compid=' + varCompId;
	     lfn_viewPDFPopup(true, url);	     

    }

    function toogleVersionUpControl(isVersonUp) {

        if(isVersonUp) {
            $("#poType").attr("disabled",true);
            $("#contractType").attr("disabled",true);
            $("#invoiceType").attr("disabled",true);

            $("#currency").attr("disabled",true);
            $("#currency").attr("disabled",true);

            $("#buyCompNm").attr("disabled",true);
            $("#fromPicPersonNm").attr("disabled",true);

            $("#sellCompNm").attr("disabled",true);
            $("#picPersonNm").attr("disabled",true);

            $("#buyCompIdBtn").hide();
            $("#buyCompIdBtn").hide();
            $("#fromPicPersonIdBtn").hide();
            $("#sellCompIdBtn").hide();
            $("#picPersonIdBtn").hide();

        } else {
            $("#poType").attr("disabled",false);
            $("#contractType").attr("disabled",false);
            $("#invoiceType").attr("disabled",false);

            $("#currency").attr("disabled",false);
            $("#currency").attr("disabled",false);

            $("#buyCompNm").attr("disabled",false);
            $("#fromPicPersonNm").attr("disabled",false);

            $("#sellCompNm").attr("disabled",false);
            $("#picPersonNm").attr("disabled",false);

            $("#buyCompIdBtn").show();
            $("#buyCompIdBtn").show();
            $("#fromPicPersonIdBtn").show();
            $("#sellCompIdBtn").show();
            $("#picPersonIdBtn").show();

        }

    }

    /*------------------------------------------------------------------------
     *  Event : SaveEndMessage()
     *  Desc. : Save End Message
     *------------------------------------------------------------------------*/
    function SaveEndMessage() {
        //----------------------------------------------
        //-- Save End Message
        if (isSavedAlert){
        	alert("[Document ID :" + document.getElementById("docId").value + "]" + "\n-----------------------------" + "\n<spring:message code="message.save.success.changed"/>");
        };        
        isSavedAlert = true;        
        doAction("SearchStage");
    }

    /*------------------------------------------------------------------------
     *  Event : autoApproval()
     *  Desc. : Auto Approval
     *------------------------------------------------------------------------*/
    function autoApproval() {
        //----------------------------------------------
        //-- 결재처리 Call. ( QUOTE결재처리, PO 생성 )
        //-- Auto Po 생성 시, QUOTE 자동 결재처리
        autoAppResult = "Y";
        if (document.getElementById('docTitle').value == "QUOTE" && SaveEquipResult == "Success" && SavePayResult == "Success") {
            fn_approvalBefore('request');
            if (autoAppResult == "Y") {
                fn_approvalAfter('AUTOPO', 'MM');
            }
            //document.frame_approval.fn_action('request' , 'REQUEST');  //-- Request    Request
            //if(autoAppResult == "Y" ) { document.frame_approval.fn_action('request' , 'MM'); }  //-- Management Request
            //if(autoAppResult == "Y" ) { document.frame_approval.fn_action('approval', 'MM'); }  //-- Management Approval
        }
    }

    /*------------------------------------------------------------------------
     *  Event : autoPoCreate()
     *  Desc. : Auto PO Create
     *------------------------------------------------------------------------*/
    function autoPoCreate() {
        //--------------------------------------
        //-- Auto PO 생성처리....
        //alert("11111 ==> "+autoAppYn+', '+autoSearchDeal+', '+autoSearchEquip+', '+autoSearchPay);
        if (autoAppYn == "Y" && autoSearchDeal == "Y" && autoSearchEquip == "Y" && autoSearchPay == "Y") {

            //----------------
            //-- 반복생성 방지위해 'N'으로 Setting.
            autoAppYn = "N";
            autoSearchDeal = "N";
            autoSearchEquip = "N";
            autoSearchPay = "N";

            //alert("autoPO ==> "+autoAppYn+', '+autoSearchDeal+', '+autoSearchEquip+', '+autoSearchPay);

            //----------------
            //-- PO 생성
            document.getElementById('docTitle').value = "PO";
            onChange('docTitle');
            doAction("SaveStage");
        }
    }

    /*------------------------------------------------------------------------
     *  Event : SelectEquip()
     *  Desc. : select Equip.
     *------------------------------------------------------------------------*/
    function SelectEquip() {
        var selEquip = "";
        var subjectCdList = "";
        var dRows = mySheetEquip.FindCheckedRow("sel");
        var subjectNullCnt = 0;
        if (dRows != "") {
            for (var r = 1; r <= mySheetEquip.LastRow() - 1; r++) {
                if (mySheetEquip.GetCellValue(r, "sel") == '1') {
                    selEquip = selEquip + "'" + mySheetEquip.GetCellValue(r, "eId") + '_' + mySheetEquip.GetCellValue(r, "equipTxCnt") + "',";

                    if(mySheetEquip.GetCellValue(r, "subject") == "") {
                        subjectNullCnt ++;
                    } else {
                        subjectCdList += "'" + mySheetEquip.GetCellValue(r, "eId") + '_' + mySheetEquip.GetCellValue(r, "equipTxCnt") + mySheetEquip.GetCellValue(r, "subject") + "',";
                    }                    
                }
            }
            selEquip = selEquip.substring(0, selEquip.length - 1);
            subjectCdList = subjectCdList.substring(0, subjectCdList.length - 1);
            document.getElementById("selEquip").value = selEquip;
        } else {
            document.getElementById("selEquip").value = "";
        }

        if(subjectNullCnt>0) {
            subjectCdList = "";
            document.getElementById("subjectCdList").value = "";
        } else {
            document.getElementById("subjectCdList").value = subjectCdList;
        }


    }

    /*------------------------------------------------------------------------
     *  Event : dataSet(gbn)
     *  Desc. : DetailInfo. View여부에 따라 Frm Data Clear/Set.
     *------------------------------------------------------------------------*/
    function dataSet(gbn) {
        var myForm = document.Frm;
        switch (gbn) {
            case "1":
                //-- Clear.
                break;

            case "2":

                //-- Data Set.
                if (mySheet.LastRow() > 0) {
                    myForm.relId.value = relIdOrg;
                    myForm.Id.value = relIdOrg;
                    myForm.docTitle.value = docTitleOrg;
                    myForm.approvalStatusCd.value =  mySheet.GetCellValue(1, "approvalStatusCd");
                    myForm.docSubj.value = mySheet.GetCellValue(1, "docSubj");
                    //myForm.sg.value = mySheet.GetCellValue(1, "sg");
                    myForm.vat.value = mySheet.GetCellValue(1, "vat");
                    myForm.offerType.value = mySheet.GetCellValue(1, "offerType");
                    
                    myForm.poType.value = mySheet.GetCellValue(1, "poType");
                    myForm.contractType.value = mySheet.GetCellValue(1, "contractType");
                    myForm.invoiceType.value = mySheet.GetCellValue(1, "invoiceType");
                    //myForm.serDealYn.value       = mySheet.GetCellValue(1,"serDealYn");
                    myForm.buyCompId.value = mySheet.GetCellValue(1, "buyCompId");
                    myForm.buyCompNm.value = mySheet.GetCellValue(1, "buyCompNm");
                    myForm.docBuyCompNm.value = mySheet.GetCellValue(1, "docBuyCompNm");
                    myForm.fromPicPersonNm.value = mySheet.GetCellValue(1, "fromPicPersonNm");
                    myForm.docFromPicPersonNm.value = mySheet.GetCellValue(1, "docFromPicPersonNm");

                    myForm.sellCompId.value = mySheet.GetCellValue(1, "sellCompId");
                    myForm.sellCompNm.value = mySheet.GetCellValue(1, "sellCompNm");
                    myForm.docSellCompNm.value = mySheet.GetCellValue(1, "docSellCompNm");
                    myForm.picPersonId.value = mySheet.GetCellValue(1, "picPersonId");
                    myForm.picPersonNm.value = mySheet.GetCellValue(1, "picPersonNm");
                    myForm.docPicPersonNm.value = mySheet.GetCellValue(1, "docPicPersonNm");

                    myForm.equipAmount.value = commify(mySheet.GetCellValue(1, "equipAmount").toString());
                    myForm.stageDate.value = mySheet.GetCellValue(1, "stageDate");
                    myForm.currency.value = currencyOrg;
                    //myForm.seller.value          = mySheet.GetCellValue(1,"seller");
                    //myForm.sellerNm.value        = mySheet.GetCellValue(1,"sellerNm");
                    //myForm.buyer.value           = mySheet.GetCellValue(1,"buyer");
                    //myForm.buyerNm.value         = mySheet.GetCellValue(1,"buyerNm");
                    //myForm.attach.value          = mySheet.GetCellValue(1,"attach");
                    myForm.remark.value = mySheet.GetCellValue(1, "remark");
                    //-------

                    myForm.subPriorSalesYn.value = mySheet.GetCellValue(1, "subPriorSalesYn");

                    myForm.warTerms.value = mySheet.GetCellValue(1, "warTerms");
                    myForm.warLaborPeriod.value = mySheet.GetCellValue(1, "warLaborPeriod");
                    myForm.warLaborRemark.value = mySheet.GetCellValue(1, "warLaborRemark");
                    myForm.warLaborDt.value = mySheet.GetCellValue(1, "warLaborDt");
                    myForm.warPartPeriod.value = mySheet.GetCellValue(1, "warPartPeriod");
                    myForm.warPartRemark.value = mySheet.GetCellValue(1, "warPartRemark");
                    myForm.warPartDt.value = mySheet.GetCellValue(1, "warPartDt");
                    myForm.priceTerms.value = mySheet.GetCellValue(1, "priceTerms");
                    myForm.priceCountry.value = mySheet.GetCellValue(1, "priceCountry");
                    myForm.priceRemark.value = mySheet.GetCellValue(1, "priceRemark");
                    myForm.packType.value = mySheet.GetCellValue(1, "packType");
                    myForm.packRemark.value = mySheet.GetCellValue(1, "packRemark");
                    myForm.pcakRespon.value = mySheet.GetCellValue(1, "pcakRespon");
                    myForm.shipBy.value = mySheet.GetCellValue(1, "shipBy");
                    myForm.shipByRemark.value = mySheet.GetCellValue(1, "shipByRemark");
                    myForm.sellBnk.value = mySheet.GetCellValue(1, "sellBnk");
                    //myForm.sellBnkRemark.value = mySheet.GetCellValue(1, "sellBnkRemark");
                    $('#sellBnk').change();
                    myForm.valDate.value = mySheet.GetCellValue(1, "valDate");

                    myForm.deliText.value = mySheet.GetCellValue(1, "deliText");
                    myForm.termsRemark.value = mySheet.GetCellValue(1, "termsRemark");
                    //myForm.offerNo.value = mySheet.GetCellValue(1, "offerNo");
                    myForm.exDate.value = mySheet.GetCellValue(1, "exDate");
                    myForm.exRate.value = commify(mySheet.GetCellValue(1, "exRate").toString());
                    myForm.dealType.value = mySheet.GetCellValue(1, "dealType");
                    myForm.opptId.value = mySheet.GetCellValue(1,"opptId");
                    if(mySheet.GetCellValue(1, "valuId")!="") {
                        myForm.valuId.value = mySheet.GetCellValue(1, "valuId");
                        myForm.valuVerId.value = mySheet.GetCellValue(1, "valuVerId");
                        myForm.dispValuId.value = mySheet.GetCellValue(1, "valuId") + "V" + mySheet.GetCellValue(1, "valuVerId");
                    }

                    myForm.preVerDocId.value = mySheet.GetCellValue(1,"preVerDocId");

                    myForm.warrTermYn.value = mySheet.GetCellValue(1,"warrTermYn");
                    myForm.warrLaborYn.value = mySheet.GetCellValue(1,"warrLaborYn");
                    myForm.warrPartYn.value = mySheet.GetCellValue(1,"warrPartYn");
                    myForm.priceTermYn.value = mySheet.GetCellValue(1,"priceTermYn");
                    myForm.packTypeYn.value = mySheet.GetCellValue(1,"packTypeYn");
                    myForm.packResYn.value = mySheet.GetCellValue(1,"packResYn");
                    myForm.shipYn.value = mySheet.GetCellValue(1,"shipYn");
                    myForm.bankYn.value = mySheet.GetCellValue(1,"bankYn");
                    myForm.validityYn.value = mySheet.GetCellValue(1,"validityYn");
                    myForm.deliveryYn.value = mySheet.GetCellValue(1,"deliveryYn");
                    myForm.remarkYn.value = mySheet.GetCellValue(1,"remarkYn");
                    
                    myForm.customerDocId.value = mySheet.GetCellValue(1,"customerDocId");
                    
                    
                    $('#attaGrpId').val(mySheet.GetCellValue(1,"attaGrpId"));
                    attaGrpIdOrg = mySheet.GetCellValue(1,"attaGrpId");

                    if(myForm.warrTermYn.value=="Y") {
                        document.Frm.chk_warrTerm.checked  = true;
                    } else {
                        document.Frm.chk_warrTerm.checked  = false;
                    }
                    if(myForm.warrLaborYn.value=="Y") {
                        document.Frm.chk_warrLabor.checked = true;
                    } else {
                        document.Frm.chk_warrLabor.checked = false;
                    }
                    if(myForm.warrPartYn.value=="Y") {
                        document.Frm.chk_warrPart.checked  = true;
                    } else {
                        document.Frm.chk_warrPart.checked  = false;
                    }
                    if(myForm.priceTermYn.value=="Y") {
                        document.Frm.chk_priceTerm.checked = true;
                    } else {
                        document.Frm.chk_priceTerm.checked = false;
                    }
                    if(myForm.packTypeYn.value=="Y") {
                        document.Frm.chk_packType.checked  = true;
                    } else {
                        document.Frm.chk_packType.checked  = false;
                    }
                    if(myForm.packResYn.value=="Y") {
                        document.Frm.chk_packRes.checked   = true;
                    } else {
                        document.Frm.chk_packRes.checked   = false;
                    }
                    if(myForm.shipYn.value=="Y") {
                        document.Frm.chk_ship.checked      = true;
                    } else {
                        document.Frm.chk_ship.checked      = false;
                    }
                    if(myForm.bankYn.value=="Y") {
                        document.Frm.chk_bank.checked      = true;
                    } else {
                        document.Frm.chk_bank.checked      = false;
                    }
                    if(myForm.validityYn.value=="Y") {
                        document.Frm.chk_validity.checked  = true;
                    } else {
                        document.Frm.chk_validity.checked  = false;
                    }
                    if(myForm.deliveryYn.value=="Y") {
                        document.Frm.chk_delivery.checked  = true;
                    } else {
                        document.Frm.chk_delivery.checked  = false;
                    }
                    if(myForm.remarkYn.value=="Y") {
                        document.Frm.chk_remark.checked    = true;
                    } else {
                        document.Frm.chk_remark.checked    = false;
                    }

                    //-- 파일첨부 Visible
                    viewAttachFiles();

                } else {

                    //-- 최초 등록시 기본값 세팅
                    docIdOrg = "";
                    relIdOrg = "";
                    docTitleOrg = 'QUOTE';
                    document.getElementById('docTitle').value = docTitleOrg;

                    //-- 파일첨부 Visible
                    viewAttachFiles();
                }

                buttonControl(); //-- Button Control.
                //subjToPriorSaleControl(); //-- Subject to Prior Sale Item Control.

                //-- Disabled
                $('#docId').attr("disabled", true);
                //$('#offerNo').attr("disabled", true);

                if ($("#docId").val() == "" && $("#relId").val() != "" && $("#relId").val() != "0") {
                    $('#dealType').attr("disabled", true);
                }

                $('#equipAmount').attr("disabled", true);
                $('#equipLowAmount').attr("disabled", true);
                $('#equipHighAmount').attr("disabled", true);
                $('#opptId').attr("disabled", true);


                //최초 외부에서 호출시에만 수행한다!(firstView는 시점차 문제가 생기지 않도록 주의한다!, 장비조회가 뒤 에 있으므로 그곳에서 false처리 한다)
                if (firstView && $('#etcFlag').val() != ''){
                    //Inventory에서 피호출시
                    if("${param.didList}" != "") {
                        $("#dealType").val("BUY");  //무조건 BUY이고 아래의 로직은 불필요해서 주석처리함! (2016.10.11 Watney요청에의해)
                        $("#offerType").val("SQ");                        
                        /*
                        var tmpArr = "${param.didList}".split(",");
    
                        if(tmpArr.length>0) {
                            if(tmpArr[0].substr(6,2)=="OB") {
                                $("#dealType").val("BUY");
                                //onChange("DealType");
                            }
    
                            if(tmpArr[0].substr(6,2)=="OS") {
                                $("#dealType").val("SELL");
                                //onChange("DealType");
                            }
    
                            if(tmpArr[0].substr(6,2)=="OR") {
                                $("#dealType").val("REFURB");
                                //onChange("DealType");
                            }
                        }
                        */
                    }
                    
                    if('${param.valuId}' != '') {	//Valuation에서 피호출시
                        $('#extFlagType').val('VA');
                        $('#valuId').val('${param.valuId}');
                        $('#valuVerId').val('${param.valuVerId}');
                        $('#simulId').val('${param.simulId}');  //등록은 필요없지만 Equip조회시 필요하다
                        $('#dispValuId').val('${param.valuId}V${param.valuVerId}');
                        /* if('${param.valuCurrCd}' != '') {
                            $('#currency').val('${param.valuCurrCd}');  //Currency
                        } */
                        $("#dealType").val("${param.dealType}");
                        if($("#dealType").val() =='BUY'){
                            $("#offerType").val("SQ");
                        }
                        // 수정가능하게 변경(2016.11.30)
                        //$("#docTitle").attr('disabled',true);
                        
                        //Deal(OPPT_ID)이 있는 경우만
                        if ("${relId}".indexOf("O") == 0){
                        	$("#opptId").val("${relId}");	//OPPT ID가 넘어 온 경우이다(realId로 넘어온다)

                        	var currCd = '${param.valuCurrCd}'.replace(/(_K|_M)/i,'');	//요청사항#994에 의해 Valuation에서 온경우 Valuation에서 넘겨준 CURRECNY_CD로 기본선택 되어야한다(2017.1.2)
                        	$("#currency").val(currCd);
                        	currencyOrg = currCd;
                        }
                    }
                    else if('${param.didList}' != '') {
                        $('#extFlagType').val('IV');                        
                    }
                }

                //-------------------------------
                //-- Document Type List에서 Shipment 삭제
                $("#docTitle option:eq(4)").remove();

                //-- Refurb Deal인 경우, Refurb Source 버튼 Visible = false
                if (myForm.dealType.value == "REFURB") {
                    document.getElementById('refurbButton').style.display = '';
                } else {
                    document.getElementById('refurbButton').style.display = 'none';
                }

                //-- Tracker에서 넘어오는 경우 'PO'로 세팅.
                /*
                if (myForm.etcFlag.value == "Y") {
                    myForm.docTitle.value = "PO";
                }
                */

                //-- Auto Po Create
                if (autoAppYn == "Y") {
                    autoSearchDeal = "Y";
                    autoPoCreate();
                }

                offerPoTypeControl(); //-- Offer/Po Type Control.

                setFromTo();
                setHightRowPrice();

                getExRate();


                if($("#docTitle").val()=="QUOTE") {
                    $("#preVerDiv").hide();
                } else {
                    $("#preVerDiv").show();
                }

                if($("#preVerDocId").val()=="") {
                    toogleVersionUpControl(false);
                } else {
                    toogleVersionUpControl(true);
                }

                if($("#docId").val()=="") {
                    $("#vat").val("N");
                }

                break;

        }

    }

    /*------------------------------------------------------------------------
     *  Event : offerPoTypeControl()
     *  Desc. : Offer Type / PO Type Control.
     *------------------------------------------------------------------------*/
    function offerPoTypeControl() {

        if (document.getElementById('docTitle').value == "QUOTE") {
            $('#offerType').attr("disabled", false);
            document.getElementById('viewOfferType').style.display = '';
            $("#valuationDiv").show();
        } else {
            document.getElementById('offerType').value = "";
            $('#offerType').attr("disabled", true);
            document.getElementById('viewOfferType').style.display = 'none';
            //$("#valuationDiv").hide();
            $("#valuationDiv").show();
        }

        if (document.getElementById('docTitle').value == "PO") {
            $('#poType').attr("disabled", false);
            document.getElementById('viewPoType').style.display = '';
            $("#valuationDiv").show();
        } else {
            document.getElementById('poType').value = "";
            $('#poType').attr("disabled", true);
            document.getElementById('viewPoType').style.display = 'none';
            $("#valuationDiv").show();
        }

        if (document.getElementById('docTitle').value == "CNTR") {
            $('#contractType').attr("disabled", false);
            document.getElementById('viewContractType').style.display = '';
            $("#valuationDiv").show();
        } else {
            document.getElementById('contractType').value = "";
            $('#contractType').attr("disabled", true);
            document.getElementById('viewContractType').style.display = 'none';
            $("#valuationDiv").show();
        }

        if (document.getElementById('docTitle').value == "INV") {
            $('#invoiceType').attr("disabled", false);
            document.getElementById('viewInvoiceType').style.display = '';
            $("#valuationDiv").show();
        } else {
            document.getElementById('invoiceType').value = "";
            $('#invoiceType').attr("disabled", true);
            document.getElementById('viewInvoiceType').style.display = 'none';
            $("#valuationDiv").show();
        }

        var dealType = mySheet.GetCellValue(1, "dealType");
        var dealDetType = mySheet.GetCellValue(1, "dealDetType");

        if (dealDetType != "" && dealDetType!=-1 && dealDetType!=undefined) {
            var typeCodeStr = "";

            if (document.getElementById('docTitle').value == "QUOTE") {
                typeCodeStr = "QUOTE_TYPE_"
            } else if (document.getElementById('docTitle').value == "PO") {
                typeCodeStr = "PO_TYPE_"
            } else if (document.getElementById('docTitle').value == "CNTR") {
                typeCodeStr = "CNTR_TYPE_"
            } else if (document.getElementById('docTitle').value == "INV") {
                typeCodeStr = "INVOICE_TYPE_"
            }

            typeCodeStr += dealType;

            if(dealType!="REFURB") {
                typeCodeStr += "_";

                if (dealDetType == "NA") {
                    typeCodeStr += "NA";
                } else if (dealDetType == "REMARKET") {
                    typeCodeStr += "REMARKET_BS";
                } else if (dealDetType == "REMARKETCOMM") {
                    typeCodeStr += "REMARKET_COMM";
                } else if (dealDetType == "REMARKETCOMM") {
                    typeCodeStr += "RENTAL";
                }
            }

            ComCallAjaxJson("comCode", typeCodeStr, setDetCd, null, typeCodeStr, "");
        } else {
            if (document.getElementById('docTitle').value == "QUOTE") {
                typeCodeStr = "QUOTE_TYPE_" + $("#dealType").val();
            } else if (document.getElementById('docTitle').value == "PO") {
                typeCodeStr = "PO_TYPE_" + $("#dealType").val();
            } else if (document.getElementById('docTitle').value == "CNTR") {
                typeCodeStr = "CNTR_TYPE_" + $("#dealType").val();
            } else if (document.getElementById('docTitle').value == "INV") {
                typeCodeStr = "INVOICE_TYPE_" + $("#dealType").val();
            }

            ComCallAjaxJson("comCode", typeCodeStr, setDetCd, null, typeCodeStr, "");
        }       
    }

    var setDetCd = function(data) {
        $(data).each(function(index, item) {
            var selectName = "";
            if (document.getElementById('docTitle').value == "QUOTE") {
                selectName = "offerType"
            } else if (document.getElementById('docTitle').value == "PO") {
                selectName = "poType"
            } else if (document.getElementById('docTitle').value == "CNTR") {
                selectName = "contractType"
            } else if (document.getElementById('docTitle').value == "INV") {
                selectName = "invoiceType"
            }

            var obj_name = item.objname;
            var f_value = item.fvalue;

            var codeArry = item.code.split("|");
            var nameArry = item.name.split("|");

            $("#" + selectName).empty();

            for (var i = 0; i < codeArry.length; i++) {
                if (i > 0) {
                    if (f_value == codeArry[i]) {
                        $("#" + selectName).append("<option value='"+codeArry[i]+"' selected>" + nameArry[i] + "</option>");
                    } else {
                        $("#" + selectName).append("<option value='"+codeArry[i]+"'>" + nameArry[i] + "</option>");
                    }
                }
            }
        });        
        
        //ComCallAjaxJson함수가 비동기 호출로 고정됨에 의해 호출이후 코드를 여기로 이동!------------------------------------------------
        
        if("${param.relId}"=="" && "${param.docId}"=="") {
            $('#dealType').attr("disabled", false);
        } else {
            $('#dealType').attr("disabled", true);
        }
        
        if(mySheet.GetCellValue(1, "offerType")!="" && mySheet.GetCellValue(1, "offerType")!=-1) {
            document.Frm.offerType.value = mySheet.GetCellValue(1, "offerType");
        }
        if(mySheet.GetCellValue(1, "poType")!="" && mySheet.GetCellValue(1, "poType")!=-1) {
            document.Frm.poType.value = mySheet.GetCellValue(1, "poType");
        }
        if(mySheet.GetCellValue(1, "contractType")!="" && mySheet.GetCellValue(1, "contractType")!=-1) {
            document.Frm.contractType.value = mySheet.GetCellValue(1, "contractType");
        }
        if(mySheet.GetCellValue(1, "invoiceType")!="" && mySheet.GetCellValue(1, "invoiceType")!=-1) {
            document.Frm.invoiceType.value = mySheet.GetCellValue(1, "invoiceType");
        }

        $('#dealType').attr("disabled", true);

        //결재진행중/후에는 Bank선택 비활성!
        if($("#docId").val() == "" || $("#approvalStatusCd").val() == "" || $("#approvalStatusCd").val() == "OPEN") {
            $('#sellBnk').removeAttr('disabled');
        }
        else{           
            $('#sellBnk').attr('disabled','disabled');
        }
        
        //만약 값이 없다면 코드선택된 값을 채워준다
        if ($('#sellBnk').find(':selected').val() != '' && $.trim($('#sellBnkRemark').val()) == ''){
            $('#sellBnkRemark').val($('#sellBnk').find(':selected').attr('desc'));
        }

        if($("#approvalStatusCd").val()=="APPROVAL_CANCEL" || $("#approvalStatusCd").val()=="REJECT") {
            $("#docTitle").attr("disabled", true);
            $("#quoteType").attr("disabled", true)
            $("#poType").attr("disabled", true);
            $("#contractType").attr("disabled", true);
            $("#invoiceType").attr("disabled", true);

        } else {
            $("#docTitle").attr("disabled", false);
            $("#quoteType").attr("disabled", false)
            $("#poType").attr("disabled", false);
            $("#contractType").attr("disabled", false);
            $("#invoiceType").attr("disabled", false);

        }
        
        //최초 외부에서 호출이고 Valuation에서 왔을때는 바꾸지 못한다
        //수정가능하게 변경(2016.11.30)
        if ($('#etcFlag').val() != '' && '${param.valuId}' != ''){
            //$("#docTitle").attr('disabled',true);
        }
      //ComCallAjaxJson함수가 비동기 호출로 고정됨에 의해 호출이후 코드를 여기로 이동!------------------------------------------------
    };

    /*------------------------------------------------------------------------
     *  Event : buttonControl()
     *  Desc. : 조회후, 문서변경후 버튼권한에 따라 처리
     *------------------------------------------------------------------------*/
	var isViewSaveButton = true; 	//Global scope로 처리해야 첨부에서도 연동할 수 있으므로!
    var custSendAttaYn = 'N';	//결재이후 날인Contract등록일 경우Y 
    var postAttaUrl = '';	//첨부팝업호출시 맨뒤에 url추가분
    function buttonControl() {    	 
    	 
        if (mySheet.GetCellValue(1, "appYn") == "Y") {
            //-- 결재상신시, 정보 수정불가.
            isViewSaveButton = false;
            //document.getElementById('paymentButton').style.display = 'none';
        } else {
            isViewSaveButton = true;
            document.getElementById('equipButton').style.display = '';
            document.getElementById('paymentButton').style.display = '';
        }

        if($("#approvalStatusCd").val()!="APPROVAL_CANCEL" && $("#approvalStatusCd").val()!="REJECT") {
            $("#copyButton").hide();
            $("#versionUpButton").hide();
        } else {
            $("#copyButton").show();
            $("#versionUpButton").show();
        }
        
      	//OPEN이면 Save버튼 보이고 이외에는 다 안보인다
      	//REQUEST일때 MM이나 Leader이면 Save버튼 보인다      	
      	if ($("#docId").val() != "" && $("#approvalStatusCd").val() != ""){
	        if ($("#approvalStatusCd").val() == "OPEN"){
	            	isViewSaveButton = true;
	        } else if($("#approvalStatusCd").val() == "REQUEST"){
	            if(appLeaderId == "${userId}" || appMmId == "${userId}"){
	            	isViewSaveButton = true;
	            }
	        } else {
	        	isViewSaveButton = false;
	        }
     	}
     	else {
     		isViewSaveButton = true;
    	}
      	
        if (isViewSaveButton){
        	$("#docButton").show();	//Save button
        	$("#paymentButton").show();	//Payment button            
        }
        else{
        	$("#docButton").hide();	//Save button
        	$("#paymentButton").hide();	//Payment button
            $("#ModifyBtn").hide(); //수정모드버튼 숨기기
        }
        
        var viewAttachButton = false;
      	//첨부IFrame제거하면서 기능추가(10 jan 2017)
		if ($('#docId').val() == '' || isViewSaveButton){	//초기문서이거나 저장상태 일때 보여준다
			viewAttachButton = true;
		}
      	
	   /********************************************************************
		*  Action. 첨부버튼 제어 계산(19 jan 2017)
		*  Desc. 날인Contract 첨부기능 요청에 의해 추가됨
		*	1. 결재후이고
		*	2. Contract이고(custSendAttaYn은 여기서만 사용하므로 다른종류의 문서에는 Null이다)
		*	3. 등록된 권한자일때
		********************************************************************/
      	custSendAttaYn = 'N';
      	postAttaUrl = '';	//첨부팝업호출시 맨뒤에 url추가분(Contract일때만)      	
      	if ($("#docTitle").val() == 'CNTR'){
      		if ($("#docId").val().indexOf('CO') == 0 && $("#approvalStatusCd").val() == "APPROVAL"){
		      	//결재이후 이고 날인첨부권한자
		        if (paytermsAuthUsers){
		        	var users = paytermsAuthUsers.map(function(e){return e.code;});
		        	if (users.indexOf(loginUserId) > -1){
		        		viewAttachButton = true;	        		
		        		custSendAttaYn = 'Y';//지금부터 등록하는 첨부는 flag달기		        		
		        	}
		        }
      		}
      		postAttaUrl = "&custSendAttaYn=" +custSendAttaYn;
      	}
      	
      	//첨부영역버튼 활성/비활성 수행
      	if (viewAttachButton){
      		$("#divAttaBtn").show();
      	}
      	else{
      		setReadOnly(true);
      	}

        <%--attaGrpId를 설정하고 list를 검색한다.------------------------%>
        /*[첨부-시작]*/
        doAction("searchAttach");
        /*[첨부-끝]*/
        <%-------------------------------------------------------%>

    }

    function mySheet_OnSearchEnd(Code, Msg, StCode, StMsg) {
        //-------------------------------
        //-- Original Value Set.
        docIdOrg = mySheet.GetCellValue(1, "docId");
        relIdOrg = mySheet.GetCellValue(1, "relId");
        docTitleOrg = mySheet.GetCellValue(1, "docTitle");
        currencyOrg = mySheet.GetCellValue(1, "currency");
        var currCd = currencyOrg.replace(/(_K|_M)/i,'');	//Deal에서 넘어온 경우 CURRECNY_CD에 _K, _M은 제거 시켜야 기본선택 가능하다(2017.1.17)
    	$("#currency").val(currCd);
    	currencyOrg = currCd;
        exRateOrg = mySheet.GetCellValue(1, "exRate");
        equipAmountOrg = mySheet.GetCellValue(1, "equipAmount");
        appYnOrg = mySheet.GetCellValue(1, "appYn");
        appMMYnOrg = mySheet.GetCellValue(1, "appMMYn");

        buyCompIdOrg = mySheet.GetCellValue(1, "buyCompId");
        buyCompNmOrg = mySheet.GetCellValue(1, "buyCompNm");
        docBuyCompNmOrg = mySheet.GetCellValue(1, "docBuyCompNm");
        sellCompIdOrg = mySheet.GetCellValue(1, "sellCompId");
        sellCompNmOrg = mySheet.GetCellValue(1, "sellCompNm");
        docSellCompNmOrg = mySheet.GetCellValue(1, "docSellCompNm");
        offerTypeOrg = mySheet.GetCellValue(1, "offerType");

        //-------------------------------
        //-- Search Deal 정보 Set.
        dataSet("2");
        //-------------------------------
        //-- Document ID와 Relation Id에 따른 관련 Data Search
        doAction("SearchTree");
        //doAction("SearchEquip");	//PDF Viewer가 추가되면서 Modify클릭시에 조회되도록 처리하여 속도이슈 되지 않도록 변경(24 jan 2017)
        if (!firstView){
            doAction("SearchEquip");
        }
      //doAction("SearchPay");	Equip조회후에 읽히도록 동기로 이동해야 해서 주석!
        doAction("SearchPdf");
        doAction("SearchPdfCol");
        
    }
    
    
    
    //-- Equip. PopUp
    function mySheetEquip_OnPopupClick(Row, Col) {
        switch (mySheetEquip.ColSaveName(Col)) {
            case "makerNm":
                break;
            case "modelNm":
                //mySheetEquip.SetCellValue(Row, "maker", "");/*issue-request-No.687에 의해 주석(17 oct)*/
                //mySheetEquip.SetCellValue(Row, "model", "");/*issue-request-No.687에 의해 주석(17 oct)*/
                mySheetEquip.SetCellValue(Row, "standardModel", "");
                mySheetEquip.SetCellValue(Row, "modelNm", "");
                mySheetEquip.SetCellValue(Row, "standardMaker", "");
                mySheetEquip.SetCellValue(Row, "makerNm", "");
                mySheetEquip.SetCellValue(Row, "categoryGrp", "");
                mySheetEquip.SetCellValue(Row, "categoryCd", "");
                
                /*issue-request-No.687에 의해 model, maker안바뀌도록 변경(17 oct)*/
                var thisModel = mySheetEquip.GetCellValue(Row, "model");
                var thisMaker = mySheetEquip.GetCellValue(Row, "maker");
                if (thisModel != ''){   //기존에 값이 있으면 안바꾸고
                    thisModel = '';
                }
                else{   //비어 있을때만 가져온다
                    thisModel = 'model';
                }
                if (thisMaker != ''){   //기존에 값이 있으면 안바꾸고
                    thisMaker = '';
                }
                else{   //비어 있을때만 가져온다
                    thisMaker = 'maker';
                }                
                window.open("pop.modelListPopupP.do?fileId=standardModel&fileNm=modelNm&fileId1=standardMaker&fileNm1=makerNm&fileNm2=" +thisModel+ "&fileNm3=" +thisMaker+ "&confirm=confirmYn&fileId4=categoryGrp&fileId5=categoryCd&SheetName=mySheetEquip", "popForm",
                    "toolbar=no, width=700, height=600, directories=no, status=no, scrollorbars=yes, resizable=yes");
                break;

            case "fabNm":
                //----------------------------------
                //-- Fab List
                //----------------------------------
                mySheetEquip.SetCellValue(Row, "fabId", "");
                mySheetEquip.SetCellValue(Row, "fabNm", "");
                window.open("pop.FabListPopup.do?fileId=fabId&fileNm=fabNm&SheetName=mySheetEquip", "popForm", "toolbar=no, width=700, height=600, directories=no, status=no, scrollorbars=yes, resizable=yes");
                break;

        }
    }
    //첨부조회후처리(22 jan 2017)
    function mySheetAttachFile_OnSearchEnd(Code, Msg, StCode, StMsg) {
    	for (var r = 1; r <= mySheetAttachFile.LastRow(); r++) {
    		if (mySheetAttachFile.GetCellValue(r, 'custSendAttaYn') == 'Y'){
    			mySheetAttachFile.SetRowBackColor(r, '#ffe6e6');
    		}
    	}
    }

    function mySheetEquip_OnSearchEnd(Code, Msg, StCode, StMsg) {
        //-------------------------------
        doAction("SearchPay");	//Equip조회후에 읽히도록 동기로 처리해야해서 이곳에서 수행함!(Remain Amount에 값이 올바로 계산되기 위함, 2017.1.2)
        unbindLink.end();
        //-- Equipment Search
		mySheetEquip.SetSumValue("no", "Sum :");
        unitPriceSumOrg = mySheetEquip.ComputeSum("|unitPrice|");

        var info = {};
        var infoPrice = {};
        var cateGrpInfo = {};
        var cateCdInfo = {};
        var subjectInfo = {};
        var moduleYn = "N";
        
        var varStatus = [];	//상태값 복원용배열
        for (var r = 1; r <= mySheetEquip.LastRow() - 1; r++) {
        	var statusOrg = mySheetEquip.GetCellValue(r, "status");
        	varStatus.push(statusOrg);	//상태값 복원배열에 등록
        	
        	//PDF추가요청에 의해 컬럼값 세팅(2017.1.5)
        	var oid = mySheetEquip.GetCellValue(r, "eId") +"_"+ mySheetEquip.GetCellValue(r, "equipTxCnt") + "_"+ mySheetEquip.GetCellValue(r, "subject");
        	mySheetEquip.SetCellValue(r, "oid", oid);        	
        	mySheetEquip.SetCellValue(r,"preVerDocId",$("#preVerDocId").val());
        	
        	info = {Type : "Text", Edit : 0};            
            if ($('#currency').val().indexOf('KRW') > -1){
            	infoPrice.Format = "#,###";
            	infoPrice.Type = "Int";
            	infoPrice.PointCount = 0;
            }
            else{
            	infoPrice.Format = "#,###.##";
            	infoPrice.Type = "Float";
            	infoPrice.PointCount = 2;
            }
            
            if (mySheetEquip.GetCellValue(r, "eId") != "New") {
                //-- 기등록 장비정보 일부는 수정불가.
                
                cateGrpInfo = {Type : "ComboEdit", ComboCode : "${strCateGrpCds}", ComboText : "${strCateGrpNms}", Edit : 0};
                cateCdInfo = {Type : "ComboEdit", ComboCode : "${bizCateCds}", ComboText : "${bizCateNms}", Edit : 0};
                mySheetEquip.InitCellProperty(r, "categoryGrp", cateGrpInfo);
                mySheetEquip.InitCellProperty(r, "categoryCd", cateCdInfo);
                //mySheetEquip.InitCellProperty(r, "maker", info);  /*issue-request-No.687에 의해 주석(17 oct)*/
                mySheetEquip.InitCellProperty(r, "makerNm", info);
                //mySheetEquip.InitCellProperty(r, "model", info);  /*issue-request-No.687에 의해 주석(17 oct)*/
                //mySheetEquip.InitCellProperty(r, "modelNm", info);    /*수정요청No.687에 의해 수정되도록 이곳 주석(13 oct.)*/
                /* Tracker 정보 수정가능.
                 mySheetEquip.InitCellProperty(r,"sn", info);
                 mySheetEquip.InitCellProperty(r,"wafer", info);
                 */

                 mySheetEquip.InitCellProperty(r, "unitPrice", infoPrice);
                 //가격수정불가조건
                 if($("#docId").val()!="" && ($("#approvalStatusCd").val()=="APPROVAL" || $("#approvalStatusCd").val()=="REQUEST" || $("#approvalStatusCd").val()=="PROCESSING")) {
                	 infoPrice.Edit = 0;                     
                     mySheetEquip.SetCellEditable(r, "unitPrice", infoPrice.Edit);
                 }
            }
            else{
            	mySheetEquip.InitCellProperty(r, "unitPrice", infoPrice);
            }
            
          	//금액복사
          	mySheetEquip.SetCellValue(r, "sumAmt", mySheetEquip.GetCellValue(r, "unitPrice"));
          	mySheetEquip.SetCellValue(r, "sumEquipHighMarketPrice", mySheetEquip.GetCellValue(r, "equipHighMarketPrice"));
          	mySheetEquip.SetCellValue(r, "sumEquipLowMarketPrice", mySheetEquip.GetCellValue(r, "equipLowMarketPrice"));
          	
        	//docId가 존재하고 외부에서 호출되지 않은 조회는 조회모드이다!
        	if ($('#docId').val() != '' && $('#extFlagType').val() == ''){
        		mySheetEquip.SetCellValue(r, "status", "");	//조회모드	
        	}

            if (!(mySheetEquip.GetCellValue(r, "status") == "Insert" || mySheetEquip.GetCellValue(r, "subject") == "" || mySheetEquip.GetCellValue(r, "docId") == "New")) {
                //-- 최초 등록시,Default 조회시 만 수정가능.(Default조회시 'R'??? )
                //-- Mapping 이나, Key Value 수정불가.
                subjectInfo = {Type : "ComboEdit", ComboCode : "${subjectCds}", ComboText : "${subjectNms}", Edit : 0};
                mySheetEquip.InitCellProperty(r, "subject", subjectInfo);
            }

            //-- Module Y/N = 'Y'인 장비가 하나라도 존재 시, Text Visibled.
            if (mySheetEquip.GetCellValue(r, "moduleYn") == "Y" && moduleYn == "N") {
                moduleYn = "Y";
            }
            
          	//Valuation에서 피호출시 (최초 화면 로딩시 한번만)
            if(firstView && '${param.valuId}' != '') {         	
            	//Deal(OPPT_ID)이 있는 경우만
                if ("${relId}".indexOf("O") == 0){
                	$("#opptId").val("${relId}");	//OPPT ID가 넘어 온 경우이다(realId로 넘어온다)                
            		mySheetEquip.SetCellValue(r, "opptId", $('#opptId').val());                	
            		mySheetEquip.SetCellValue(r, "subject", "TOOL_PRICE");	//요청사항#994에 의해 Valuation에서 온경우 TOOL PRICE로 기본선택되어야한다(2017.1.2)
            	}
            }
        }
        

        //-- Text Visibled...
        /* if (moduleYn == "Y") {
            document.getElementById('viewText').style.display = '';
        } else {
            document.getElementById('viewText').style.display = 'none';
        } */

        //-- Auto Po Create
        if (autoAppYn == "Y") {
            autoSearchEquip = "Y";
            autoPoCreate();
        }

      	//기능수정 #903에 의해 문서(Document_PDF_20161221.pptx) Page 16에 의해 주석처리함(2016.12.26)
        /*
        if (document.getElementById('docTitle').value == "PO" || document.getElementById('docTitle').value == "CNTR") {
            mySheetEquip.SetColHidden("webYn", 0);
            mySheetEquip.SetColHidden("featuredYn", 0);
        } else {
            mySheetEquip.SetColHidden("webYn", 1);
            mySheetEquip.SetColHidden("featuredYn", 1);
        }
        */

        setAmount();
        
        //Equip-PDF체크 처리(신규문서이면 전체선택 및 하단 PDF Print Default값 처리)(2016.12.29)        
        if ($('#docId').val() == ''){
        	//문서전환시는 수행 하지 않고 유지해야한다(2017.1.4)
        	if ($('#extFlagType').val() != ''){	//외부에서 최초 장비조회시 전체선택한다(2016.1.4)
	            mySheetEquip.CheckAll("pdfYn", 1, 0);	//요청, 문서전환이 아니면 전체선택(2016.12.30)
	        
	          	//PDF Print
	          	var pdfPrintDefaultCollection = ['PAY_TERMS_COL:AMOUNT','PAY_TERMS_COL:BY','PAY_TERMS_COL:BPROCESS','PAY_TERMS_COL:REMARK','EQUIP_COL:SGNO','EQUIP_COL:SERIAL','ETC_COL:PRICE'];
	          	for (e in pdfPrintDefaultCollection){
	          		$("input[name=pdfColVal][value='" +pdfPrintDefaultCollection[e]+ "']").prop("checked", true);
	          	}
        	}
        	else{	//onChange for docTitle
        		//Select if there are any selected from the original(2017.1.5)
        		mySheetEquip.CheckAll("pdfYn", 0, 0);
        		var row;
        		$(pdfSelRows).each(function(i, e){
        			row = mySheetEquip.FindText("oid", e);
        			if (row > -1){
        				mySheetEquip.SetCellValue(row, "pdfYn", "Y");
        			}
        		});
        	}
        }
        
        mySheetEquip.CheckAll("sel", 1, 0);	//조회후 항상 선택해달라는 요청에 의해!(2016.12.30)
        //상태값 복원처리(저장시 속도개선효과)
        if ($('#docId').val() != ''){	//신규가 아닐때만
	        for (var r = 1; r <= mySheetEquip.LastRow() - 1; r++) {
	        	mySheetEquip.SetCellValue(r, "status", varStatus[r-1]);
	        }
        }
        
        SetRemainAmount();
        
        firstView = false;	//최초 조회 Flag처리
    }
    var pdfSelRows;
    
    //-- Category
    function mySheetEquip_OnChange(Row, Col, Value, OldValue, RaiseFlag) {
        if (Row < 1)
            return;

        var equipValidCheck = new Array();
        var equipCnt = mySheetEquip.LastRow() - 1;
        
        switch (mySheetEquip.ColSaveName(Col)) {
		case "pdfYn" :
			SetRemainAmount();
			
		break;

		case "subject" : //Subject변경시
            
            //issue-request-No.685 : Deal Drop된 장비 대상으로 Tool Price 문서 생성 불가, 용역 문서 생성 가능 요청에 의해 기능추가
            var thisSubjectCd = mySheetEquip.GetCellValue(Row, "subject");
            var thisDealStatusCd = mySheetEquip.GetCellValue(Row, "equipDealStatusCd");
            if (thisSubjectCd == 'TOOL_PRICE' && thisDealStatusCd == 'DROP'){
                alert("<spring:message code="message.sp.cannottoolprice"/>");   //Deal Drop된 장비 대상으로 Tool Price 문서 생성 불가합니다             
                return false;
            }            

            //var newDeal = mySheetEquip.GetCellValue(Row, "opptId");
            var newDeal = $("#opptId").val();	//Header와 비교하도록 기능 변경
            var toolCnt = 0;
            var dealCnt = 0;

            for (var r = 1; r <= equipCnt; r++) {

                if (mySheetEquip.GetCellValue(r, "status") != "D") {

                    if (mySheetEquip.GetCellValue(r, "subject") !="") {
                        equipValidCheck[r - 1] = mySheetEquip.GetCellValue(r, "eId") + "|" + mySheetEquip.GetCellValue(r, "subject"); //TOOL_PRICE
                    }

                    if (mySheetEquip.GetCellValue(r, "subject") == "TOOL_PRICE") {
                        toolCnt ++;
                    }
                }
            }
            
            if (Value == "TOOL_PRICE" || Value == "DEPOSIT_FOR_BID") {
                if($("#docTitle").val()=="QUOTE")  {
                    if($("#offerType").val()=="MQ" || $("#offerType").val()=="RQ") {
                        mySheetEquip.SetCellValue(Row, 'subject', '');
                        alert("<spring:message code="message.sp.rentaltoolprice"/>");
                        return false;
                    }
                }

                if($("#docTitle").val()=="PO")  {
                    if($("#poType").val()=="MP" || $("#poType").val()=="RP") {
                        mySheetEquip.SetCellValue(Row, 'subject', '');
                        alert("<spring:message code="message.sp.rentaltoolprice"/>");
                        return false;
                    }
                }

                if($("#docTitle").val()=="CNTR")  {
                    if($("#contractType").val()=="MC" || $("#contractType").val()=="MC") {
                        mySheetEquip.SetCellValue(Row, 'subject', '');
                        alert("<spring:message code="message.sp.rentaltoolprice"/>");
                        return false;
                    }
                }

                if($("#docTitle").val()=="INV")  {
                    if($("#invoiceType").val()=="MI" || $("#invoiceType").val()=="RI") {
                        mySheetEquip.SetCellValue(Row, 'subject', '');
                        alert("<spring:message code="message.sp.rentaltoolprice"/>");
                        return false;
                    }
                }

                if($("#opptId").val()=="") {
                    mySheetEquip.SetCellValue(Row, 'subject', '');
                    alert("<spring:message code="message.sp.withoutrealateddeal"/>");
                    return false;
                } else {
                    if($("#dealType").val()=="REFURB") {
                        mySheetEquip.SetCellValue(Row, 'subject', '');
                        alert("message.sp.withrefurbdeal");
                        return false;
                    }
                }                
            }

            if(toolCnt>0) {
                for(var r = 1; r <= equipCnt; r++) {
                    if(r!=Row) {
                        if (mySheetEquip.GetCellValue(r, "status") != "D" && newDeal != "") {
                            if (mySheetEquip.GetCellValue(r, "opptId") != "" && mySheetEquip.GetCellValue(r, "opptId") != newDeal) {
                                dealCnt ++;
                            }
                        }
                    }
                }

                if(dealCnt>0) {
                    for(var r = 1; r <= equipCnt; r++) {
                        mySheetEquip.SetCellValue(r, 'subject', '');
                    }

                    alert("<spring:message code="message.sp.toolsetsamedeal"/>");
                    return false;
                }
            }

            if(toolCnt==0 && Value == "DEPOSIT_FOR_BID") {
                mySheetEquip.SetCellValue(Row, 'subject', '');
                alert("<spring:message code="message.sp.toolfirst"/>");
                return false;
            }

            if(Value == "DEPOSIT_FOR_BID") {
                var toolEid = mySheetEquip.GetCellValue(Row, "eId");

                toolCnt = 0;
                for (var r = 1; r <= equipCnt; r++) {
                    if (mySheetEquip.GetCellValue(r, "status") != "D") {
                        if (mySheetEquip.GetCellValue(r, "subject") == "TOOL_PRICE" && mySheetEquip.GetCellValue(r, "eId") == toolEid) {
                            toolCnt ++;
                        }
                    }
                }

                if(toolCnt==0) {
                    mySheetEquip.SetCellValue(Row, 'subject', '');
                    alert("<spring:message code="message.sp.toolfirst"/>");
                    return false;
                }
            }        
            
		break;

		case "unitPrice":	//단가 수정시
			mySheetEquip.SetCellValue(Row, "sumAmt", mySheetEquip.GetCellValue(Row, "unitPrice"));
			break;
		case "equipHighMarketPrice":
			mySheetEquip.SetCellValue(r, "sumEquipHighMarketPrice", mySheetEquip.GetCellValue(r, "equipHighMarketPrice"));
			break;
		case "equipLowMarketPrice":
			mySheetEquip.SetCellValue(r, "sumEquipLowMarketPrice", mySheetEquip.GetCellValue(r, "equipLowMarketPrice"));
			break;			
		}

        setAmount();    //장비가격정보 합계 계산

        if (equipValidCheck != null && equipValidCheck != undefined && equipValidCheck.length > 0) {
            var checkNum = 0;

            for (var i = 0; i < equipValidCheck.length; i++) {
                if (equipValidCheck[i] == (mySheetEquip.GetCellValue(Row, "eId") + "|" + mySheetEquip.GetCellValue(Row, "subject"))) {
                    checkNum++;
                }
            }

            if (checkNum > 1) {
                alert("<spring:message code="message.sp.samesubject"/>");
                mySheetEquip.SetCellValue(Row, 'subject', '');
                return false;
            }
        }

        //사용자가 입력하는 경우에만 저장 데이터 생성
        if (RaiseFlag == 0) {
        	//기능수정 #903에 의해 문서(Document_PDF_20161221.pptx) Page 16에 의해 Category1이 없어짐으로 아래주석내용 필요없어짐(2016.12.26)
        	switch (mySheetEquip.ColSaveName(Col)) {
                case "categoryGrp":
                	
                    var categoryCombo = ComCallAjaxSheetCombo("bizCateCd", "BIZ_CATE_CD", Value);
                    mySheetEquip.CellComboItem(Row, "categoryCd", {ComboText : categoryCombo[1], ComboCode : categoryCombo[1]});
                    mySheetEquip.SetCellValue(Row, 'categoryCd', '');
                    break;

                case "maker":
                    /*issue-request-No.687에 의해 주석(17 oct)*/
                    //mySheetEquip.SetCellValue(Row, "makerNm", "");
                    //mySheetEquip.SetCellValue(Row, "standardMaker", "");
                    
                    break;

                case "model":
                    /*issue-request-No.687에 의해 주석(17 oct)*/
                    /*
                    mySheetEquip.SetCellValue(Row, "modelNm", "");
                    mySheetEquip.SetCellValue(Row, "standardModel", "");
                    mySheetEquip.SetCellValue(Row, "categoryGrp", "");
                    mySheetEquip.SetCellValue(Row, "categoryCd", "");
                    var model = Value;
                    var strStandardMaker = "";
                    var strStandardModel = "";
                    var strCategoryGrp = "";
                    var strCategoryCd = "";
                    var compNm = "";
                    var modelNm = "";

                    if (model != "") {
                        var params = {model : model, standardMaker : strStandardMaker, standardModel : strStandardModel, compNm : compNm, modelNm : modelNm, categoryGrp : strCategoryGrp, categoryCd : strCategoryCd};
                        ComCallAjaxUrl('getCategoryCall.do', params, getCategoryCall);
                    }
                    */
                    break;

            }

            //---------------------------------------------------
            //-- Equipment Data변경 시, Payment Amount값 다시 Set.
            //var unitPriceSum = mySheetEquip.GetCellValue(mySheetEquip.LastRow(), "unitPrice");
            var unitPriceSum = mySheetEquip.GetSumValue(0, "sumAmt");
            //-- Delete Check후, 다시 UnCheck하는 경우, 금액이 처음과 동일해지니, 수정작업이 있는 모든상황에서 체크
            //if( unitPriceSumOrg != unitPriceSum ){
            var payCnt = mySheetPay.LastRow() - 1;
            
          	//0보다 작은 경우 처리해달라고 현업(Allie,..)에서 요청 이부분 제거(2017.1.18)
/*             if (unitPriceSum > 0) {
                mySheetPay.SetHeaderCheck(0, "delete", 0);
                for (var r = 1; r <= payCnt; r++) {
                    //-- Amount로 설정되어 있는 경우는 그대로, PERCENT만 수정.
                    mySheetPay.SetCellValue(r, "delete", "0");
                    
                    //기능수정 #903에 의해 문서(Document_PDF_20161221.pptx) Page 16에 의해 주석처리되고 아래 코드로 변경함(2016.12.26)
                    //if (mySheetPay.GetCellValue(r, "pmtTermsRate") == "PERCENT") {
                    //    var rate = mySheetPay.GetCellValue(r, "pmtTermsValue");
                    //    var amt = unitPriceSum * (rate * 0.01)
                    //    mySheetPay.SetCellValue(r, "pmtTermsAmt", amt);
                    //}
                    if (mySheetPay.GetCellValue(r, "pmtTermsValue") != 0) {
                        var rate = mySheetPay.GetCellValue(r, "pmtTermsValue");
                        if (rate == "") rate = 0;
                        var amt = unitPriceSum * (rate * 0.01);
                        mySheetPay.SetCellValue(r, "pmtTermsAmt", amt);
                        mySheetPay.SetCellValue(r, "sumAmt", amt);
                    }
                }
            }          	
            else {
                //-- Amt가 0이므로 항목 모두 삭제처리(0이하 일때 자동삭제기능 요청에 의해처리2016.9월 이전요청)
                mySheetPay.SetHeaderCheck(0, "delete", 1);
                for (var r = payCnt; r >= 1; r--) {
                    mySheetPay.SetCellValue(r, "delete", "1");
                }
            } */
            //}
            //---------------------------------------------------
            //위에 로직 제거 하여 필요함 부분만 처리(2017.1.18)
			for (var r = 1; r <= payCnt; r++) {
                if (mySheetPay.GetCellValue(r, "pmtTermsValue") != 0) {
                    var rate = mySheetPay.GetCellValue(r, "pmtTermsValue");
                    if (rate == "") rate = 0;
                    var amt = unitPriceSum * (rate * 0.01);
                    mySheetPay.SetCellValue(r, "pmtTermsAmt", amt);
                    mySheetPay.SetCellValue(r, "sumAmt", amt);
                }
            }

        }

    }

    /*------------------------------------------------------------------------
     *  Event : OnDblClick(Row, Col, Value, CellX, CellY, CellW, CellH)
     *  Desc. : 데이터 영역의 셀을 마우스로 더블 클릭시
     *------------------------------------------------------------------------*/
    function mySheetEquip_OnDblClick(Row, Col, Value, CellX, CellY, CellW, CellH) {
        if (Row == null || Row == 0 /*|| ${sa} == 0 */)
            return;

        /* switch (mySheetEquip.ColSaveName(Col).toString()) {
            case "modelNm":

                if (mySheet.GetCellValue(1, "appMMYn") == "N") {
                    //-- 결재처리시 Divide불가.
                    //---------------------------------------------------------------
                    //-- Standard Model Name DB Click시, Module Divide POPUP.(Dylan)
                    if (mySheetEquip.GetCellValue(Row, "eId") == "New") {
                        alert("<spring:message code="message.save.fail.eid"/>");
                    } else {

                        if (mySheetEquip.GetCellValue(Row, "pnc") == 'M') {
                            if (document.getElementById('docTitle').value == "QUOTE" || document.getElementById('docTitle').value == "PO") {

                                var eid = mySheetEquip.GetCellValue(Row, "eId");
                                var equipTxCnt = mySheetEquip.GetCellValue(Row, "equipTxCnt");
                                var modelId = mySheetEquip.GetCellValue(Row, "standardModel");
                                var makerId = mySheetEquip.GetCellValue(Row, "standardMaker");
                                var moduleYn = mySheetEquip.GetCellValue(Row, "moduleYn");
                                var docId = mySheetEquip.GetCellValue(Row, "docId");
                                window.open("TR0242P.do?eid=" + eid + "&equipTxId=" + equipTxId + "&menuId=SP0300M&modelId=" + modelId + "&makerId=" + makerId + "&moduleYn=" + moduleYn + "&docId=" + docId, "popForm",
                                    "toolbar=no, width=1100, height=700, directories=no, status=no, scrollorbars=yes, resizable=yes");

                            } else {
                                alert("<spring:message code="message.save.fail.divideCheck"/>");
                                return;
                            }
                        } else {
                            alert("<spring:message code="message.save.fail.gridPartsNoDivided"/>");
                        }
                    }
                    //---------------------------------------------------------------
                }
                break;
        } */
    }

    /*------------------------------------------------------------------------
     *  Event : OnSaveEnd(Code, Msg, StCode, StMsg)
     *  Desc. : 저장 처리를 완료 후
     *------------------------------------------------------------------------*/
    function mySheetEquip_OnSaveEnd(Code, Msg, StCode, StMsg) {
    	 
        switch (Code) {
            case "2222":
                //-- Opportunity 저장 시, Standard Maker/Model정보 없으면 저장 안되도록
                SaveEquipResult = "Fail";
                alert(Code + " : <spring:message code="message.save.fail.standardCheck"/>");
                break;

            case "66":
                //-- Payment Id
                //-- 다른 PO등에 의해 payment가 이미 생성되었으므로, 해당 Equip.은 삭제처리후 저장.
                SaveEquipResult = "Fail";
                alert(Code + " : <spring:message code="message.save.fail.existpayment"/>");
                break;

            case "5555":
                //-- 해당 장비가, 결재처리된 Doc Id에 등록된 장비여부 체크
                SaveEquipResult = "Fail";
                alert(Code + " : <spring:message code="message.save.fail.appPOequip"/>");
                break;

            case "7777":
                //-- WTBS에 입력된 장비만 등록가능.
                SaveEquipResult = "Fail";
                alert(Code + " : <spring:message code="message.save.fail.onlywtbwts"/>");
                break;

            case "8888":
                //-- 하나의 WTBS에 연결된 Deal/Doc중 동일장비 등록시.
                SaveEquipResult = "Fail";
                alert(Code + " : <spring:message code="message.save.fail.equipdup"/>");
                break;

            case "99":
                break;
            case "999":
                break;
            case "9999":
                //-- 동일한 EID가 존재시
                SaveEquipResult = "Fail";
                alert(Code + " : <spring:message code="message.check.null.dupcode"/>");
                break;

            default:
            	
				 equipSave_successCallback();

                 //저장후 외부호출Flag 지우기
                 $('#etcFlag').val('');
                 $('#selEquip').val('');
                 $('#subjectCdList').val('');//조회시에 장비 조회 안되므로 비워준다
                 $('#didList').val('');
                 isNotFirstSave = false;	//저장되었음
                 $('#extFlagType').val('');//Server에서도 사용해아 함으로 저장후에는 비워준다
                 sevingEquip = false;	//저장완료임으로 조회 수행가능 하도록 처리
                 
                 //수정된 경우에만 장비조회
                 if (mySheetEquip.IsDataModified()){
					doAction("SearchEquip");                    
                 }
                 else{
					doAction("SearchPay");	//위에서 조회되지 않으면 이부분 조회하도록 한다
                 }
                 
                break;
        }
    }

    function mySheetEquip_OnRowSearchEnd(row) {

        //-- Subject = 'Refurb'인 경우, 수정불가
        //if(mySheetEquip.GetCellValue(row,"subject") == "REFURB" ){
        //  mySheetEquip.SetRowEditable(row, 0);
        //}

        //-- 결재아닌 경우에만 팝업위한 Color, Underline표시.
        //if (mySheet.GetCellValue(1, "appMMYn") == "N") {
        //    mySheetEquip.SetCellFontColor(row, "modelNm", "#428BCF");
        //    mySheetEquip.SetCellFontUnderline(row, "modelNm", 1);
        //}

        //-- StandardMaker, StandardModel이 없는경우, 배경색 지정.
        var tempYn = "N"; //-- Standard Maker/Model이 없는 경우, Count
        if (mySheetEquip.GetCellValue(row, "makerNm") == "") {
            mySheetEquip.SetCellBackColor(row, "makerNm", "AAA5F8");
            tempYn = "Y";
        }
        if (mySheetEquip.GetCellValue(row, "modelNm") == "") {
            mySheetEquip.SetCellBackColor(row, "modelNm", "AAA5F8");
            tempYn = "Y";
        }

        if (tempYn == "Y") {
            tempCnt = tempCnt + 1;
        }
        mySheetEquip.SetCountFormat("[ Temp " + tempCnt + " / Total ROWCOUNT ]");

    }
    


    /*------------------------------------------------------------------------
     *  Event : OnAfterEdit
     *  Desc. : Payment Terms의 금액계산
     *------------------------------------------------------------------------*/
    function mySheetPay_OnAfterEdit(Row, Col) {
        if (mySheetPay.ColSaveName(Col) == "pmtTermsRate" || mySheetPay.ColSaveName(Col) == "pmtTermsValue") {
            setPayValue(Row);
        }
    }

    function mySheetPay_OnSearchEnd(Code, Msg, StCode, StMsg) {
        mySheetPay.SetSumValue("sortOrder", "Amount Sum :");

        //-- Auto Po Create
        if (autoAppYn == "Y") {
            autoSearchPay = "Y";
            autoPoCreate();
        }

        savingPay = false;
        var backColor = "#FFFFFF";

        var info = {};

        for (var r = 1; r <= mySheetPay.LastRow() - 1; r++) {
            info = {Edit : 0};
            backColor = "#FFFFFF";
            
            if ($('#currency').val().indexOf('KRW') > -1){
            	info.Format = "#,###";
            	info.Type = "Int";
            	info.PointCount = 0;
            }
            else{
            	info.Format = "#,###.##";
            	info.Type = "Float";
            	info.PointCount = 2;
            }
            
            if($("#docId").val()!="" && ($("#approvalStatusCd").val()=="APPROVAL" || $("#approvalStatusCd").val()=="REQUEST" || $("#approvalStatusCd").val()=="PROCESSING")) {
                mySheetPay.SetColProperty(r, "pmtTermsAmt", info);
                mySheetPay.SetCellBackColor(r, "pmtTermsAmt", backColor);
            }
            else{
            	//Amount의 수정상태 처리                
                var value = mySheetPay.GetCellValue(r, "pmtTermsValue");                
                if (value == ""){	//%가 없을때는 Amount수정가능
                	info.Edit = 1;
                }
                else{
           			backColor = "#EFEFEF";
                }
            }
            mySheetPay.SetColProperty(r, "pmtTermsAmt", info);
        	mySheetPay.SetCellEditable(r, "pmtTermsAmt", info.Edit);
        	mySheetPay.SetCellBackColor(r, "pmtTermsAmt", backColor);
        	
        	mySheetPay.SetCellValue(r, "sortOrder", r);
        	setPayValue(r);
        }
    }    

    function mySheetPay_OnChange(Row, Col, Value, OldValue, RaiseFlag) {

        if (Row < 1)
            return;

        var equipValidCheck = new Array();
        var equipCnt = mySheetEquip.LastRow() - 1;

        var tmpValue = mySheetPay.GetCellValue(Row, "pmtTermsValue");
        var info = {Type : "Float",Edit : 0};
        var backColor = "#EFEFEF";
        
        switch (mySheetPay.ColSaveName(Col)) {
        case "pmtTermsValue":	//Percent입력시에는 금액이 비활성, 자동계산!
        
        	if (savingPay) break;	//저장전 변경시는 아래 수행하지 않는다
        	
        	//pmtTermsRate자동전환:Percent에 값이 있으면 PERCENT이고 Null문자일때는 AMOUNT로 인식하도록 한다

	        if (Value == ""){	//현재입력된 값이 없으면
				mySheetPay.SetCellValue(Row, "pmtTermsAmt", "0");
				mySheetPay.SetCellValue(Row, "pmtTermsRate", "AMOUNT");
	        }
	        else if(parseFloat(Value)>100 || parseFloat(Value)<0) {	//입력됬는데 범위값이 아니면
				alert("<spring:message code="message.sp.paymentbetween"/>");
				mySheetPay.SetCellValue(Row, "pmtTermsValue", "0");
				mySheetPay.SetCellValue(Row, "pmtTermsAmt", "0");
				mySheetPay.SetCellValue(Row, "pmtTermsRate", "PERCENT");
			}
			else{
				mySheetPay.SetCellValue(Row, "pmtTermsRate", "PERCENT");
			}

			if (Value == ""){
				info.Edit = 1;
				backColor = "#FFFFFF";
			}
             
			mySheetPay.InitCellProperty(Row, "pmtTermsAmt", info);
			mySheetPay.SetCellEditable(Row, "pmtTermsAmt", info.Edit);
			mySheetPay.SetCellBackColor(Row, "pmtTermsAmt", backColor);
			mySheetPay.SetCellValue(Row, "sumAmt", mySheetPay.GetCellValue(Row, "pmtTermsAmt"));
             
        	break;
        	
        case "pmtTermsAmt":	//금액을 입력시에는 Percent가 없어야 한다
        	if (tmpValue == ""){
        		mySheetPay.SetCellValue(Row, "pmtTermsRate", "AMOUNT");
        		mySheetPay.SetCellValue(Row, "sumAmt", mySheetPay.GetCellValue(Row, "pmtTermsAmt"));
	        }
        	break;
        }             
    }
    //Sum내용 변경시 : AutoSum의 내용을 Amount의 밑에 Sum으로 복사해준다
    function mySheetPay_OnChangeSum(Row,  Col) {

    	var sumValue = mySheetPay.GetSumValue(0, "sumAmt");
		mySheetPay.SetSumValue(0, "pmtTermsAmt", commify(sumValue));
    }
    
    //PDF IBSheet Event---------------------------------------------------------
    function mySheetPdf_OnSaveEnd(Code, Msg, StCode, StMsg) {
        doAction("SearchPDF");
    }
    function mySheetPdf_OnChange(Row, Col, Value, OldValue, RaiseFlag) {
    	if (Row < 1)
            return;
    	
    	switch (mySheetPdf.ColSaveName(Col)) {
    		case "amt":
    			mySheetPdf.SetCellValue(Row, "sumAmt", mySheetPdf.GetCellValue(Row, "amt"));
    		case "delete":
    			SetRemainAmount();
    			break;
    		
    		case "":
    			break;
    	}

        var amount = 0.0;
        if (mySheetPdf.GetCellValue(Row, "status") != "D") {
        	var unitPrice = mySheetPdf.GetCellValue(Row, 'unitPrice');
        	var qty = mySheetPdf.GetCellValue(Row, 'qty');
        	amount = 0;
        	if (unitPrice != 0 && qty != 0){
        		amount = unitPrice * qty;
        		mySheetPdf.SetCellValue(Row, 'amt', amount);
        	}
        }
    }
    
  	//Sum내용 변경시 : AutoSum의 내용을 Amount의 밑에 Sum으로 복사해준다
    function mySheetPdf_OnSearchEnd(Code, Msg, StCode, StMsg) {

    	mySheetPdf.SetSumValue("sortOrder", "Amount Sum :");
    	
    	for (var r = 1; r <= mySheetPdf.LastRow()-1; r++) {
    		mySheetPdf.SetCellValue(r, "sumAmt", mySheetPdf.GetCellValue(r, "amt"));
    		mySheetPdf.SetCellValue(r, "sortOrder", r);
    	}

        if (showMode === mode.lookAt.EDIT){
            viewPDFComponent(); //PDF도 새로 조회한다
        }
    }
    
  	//합계 행에 값이 바뀌었을 때, 계산 정보 표시
    function mySheetPdf_OnChangeSum(Row,  Col) {
    	var sumValue = mySheetPdf.GetSumValue(0, "sumAmt");
		mySheetPdf.SetSumValue(0, "amt", commify(sumValue));
		
    	SetRemainAmount();
    }
    function mySheetPdf_OnCheckAllEnd(Col, Value) {
    	SetRemainAmount();
    }
    function mySheetEquip_OnChangeSum(Row,  Col) {
    	var sumValue = mySheetEquip.GetSumValue(0, "sumAmt");
		mySheetEquip.SetSumValue(0, "unitPrice", commify(sumValue));
		
    	SetRemainAmount();
    }
    function mySheetEquip_OnCheckAllEnd(Col, Value) {
    	SetRemainAmount();
    }
    
    //PDF IBSheet Event--------------------------------------------------------->
    
    //환율변경시 소수점제어
    function change_currency(){
		//return;	//작업중이므로 실행안함
    	var formatInfo = {};
        if ($('#currency').val().indexOf('KRW') > -1){
        	formatInfo = {Type:"Int", PointCount : 0, Format:"#,###"};
        }
        else{
        	formatInfo = {Type:"Float", PointCount : 2, Format:"#,###.##"};
        }
        //Equip
        for (var r = 1; r <= mySheetEquip.LastRow(); r++) {        	
        	mySheetEquip.InitCellProperty(r, "unitPrice", formatInfo);
        }
        //Pay Terms
        for (var r = 1; r <= mySheetPay.LastRow(); r++) {        	
        	mySheetPay.InitCellProperty(r, "pmtTermsAmt", formatInfo);
        }
        //Pdf
        for (var r = 1; r <= mySheetPdf.LastRow(); r++) {        	
        	mySheetPdf.InitCellProperty(r, "amt", formatInfo);
        }
    }

    function setPayValue(Row) {
        //var totalAmt = mySheetEquip.GetCellValue(mySheetEquip.LastRow(), "unitPrice"); //-- 저장된 Equipment Amount.
        var totalAmt = mySheetEquip.GetSumValue(0, "sumAmt");

        var rateAmtGbn = ""; //-- Rate/Amount 구분
        var value = 0; //-- Rate/Amount Value
        var valueCalc = 0; //-- Rate/Amount Value Calculation.

        rateAmtGbn = mySheetPay.GetCellValue(Row, "pmtTermsRate");
        value = mySheetPay.GetCellValue(Row, "pmtTermsValue");
        if (rateAmtGbn == "PERCENT") {
            //-- % 선택 시
            if (value == "") value = 0;
            valueCalc = totalAmt * (value * 0.01);
        } else if (rateAmtGbn == "AMOUNT") {
            //-- Amount 선택 시
            valueCalc = mySheetPay.GetCellValue(Row, "pmtTermsAmt");            
            mySheetPay.SetCellValue(Row, "pmtTermsValue", "");	//0이면 안보이게 해달라는 요청에 의해 Percent지워준다            
        }
        
        mySheetPay.SetCellValue(Row, "pmtTermsAmt", valueCalc);
        mySheetPay.SetCellValue(Row, "sumAmt", valueCalc);

    }

    /*------------------------------------------------------------------------
     *  Event : onChange
     *  Desc. : 특정정보 변경 시
     *------------------------------------------------------------------------*/
    //-- ( Deal Data Check. )
    function onChange(Col) {
        switch (Col) {
            case "docTitle":	//문서새로 생성하기 위해 ComboBox변경

            	//결제제약제거(2nov2016) 현업요청에 의해서.
            	/*
                if ($("#docId").val() != ""){
                    if($("#approvalStatusCd").val()!="APPROVAL") {
                        alert("<spring:message code="message.sp.cannotchagestage"/>");
                        $("#docTitle").val(docTitleOrg);
                        return false;
                    }
                }*/
                
                selEquipYn = "Y";
                if (document.getElementById('docTitle').value != docTitleOrg) {	//원본과 현재가 (DocTitle가) 다르면
                    selEquipYn = "N";

                    if($("#relId").val()!=undefined && $("#relId").val()!="" && $("#relId").val()!="0") {
                        if($("#docId").val()!=undefined && $("#docId").val() != "" && $("#docId").val() != "0") {
                            selectEquipCount(); //-- Equip.이 선택되었는지 체크.
                        }
                    }
                }

                if (selEquipYn == "Y") {	//장비를 선택했으면
                	
            		//Momory for PDF and Sel checked(2017.1.5)
            		pdfSelRows = [];
            		//Check if PDF
            		var pdfRows = mySheetEquip.FindCheckedRow("pdfYn", {ReturnArray:1});
            		$(pdfRows).each(function(i,e){
            			//Check if Sel
            			if (mySheetEquip.GetCellValue(e, "sel") == "1"){
             				pdfSelRows.push(
             					mySheetEquip.GetCellValue(e, "eId") + '_' +
             					mySheetEquip.GetCellValue(e, "equipTxCnt") + '_' +
             					mySheetEquip.GetCellValue(e, "subject")
             				);
            			}
            		});

                    SelectEquip();	//장비에 대해 선택한 목록 직렬화
                    IdClear();	//초기화 및 문서전환시 Id및 장비,PayTerm재조회

                    //-- iFrame Reload.
                    if (document.getElementById('docId').value == "") {
                        mySheet.SetCellValue(1, "appYn", "N");
                        mySheet.SetCellValue(1, "appMMYn", "N");
                      	//결재IFrame없애며 주석처리(2017.1.10)
                        //$('#frame_approval').prop("src", "${pageContext.request.contextPath}/approval.do?doc_id=" + document.getElementById('docId').value);
                        if ($('#doc_id').val() != $('#docId').val()){
                        	$('#doc_id').val($('#docId').val());
                        	initApproval();
                        }
                        
                      	//첨부ID초기화
                        $('#attaGrpId').val('');
                        
                    } else {
                    	//결재정보 복원
                        mySheet.SetCellValue(1, "appYn", appYnOrg);
                        mySheet.SetCellValue(1, "appMMYn", appMMYnOrg);

                        if ($('#doc_id').val() != $('#docId').val()){
                        	$('#doc_id').val($('#docId').val());
                        	initApproval();
                        }
                        
                      	//첨부ID 복원
                        $('#attaGrpId').val(attaGrpIdOrg);

                    }
                    buttonControl(); //-- Button Control.

                } else {
                    if($("#docId").val()!="") {
                        document.getElementById('docTitle').value = docTitleOrg;
                        //fromToControl();
                    }
                }

                if (document.getElementById('docTitle').value == "PO" || document.getElementById('docTitle').value == "CNTR") {
                	//기능수정 #903에 의해 문서(Document_PDF_20161221.pptx) Page 16에 의해 주석처리함(2016.12.26)
                	/*
                	mySheetEquip.SetColHidden("webYn", 0);
                    mySheetEquip.SetColHidden("featuredYn", 0);
                    */
                    //초기값 체크
                    if ($('#docId').val() == ''){
                        for (var r = 1; r < mySheetEquip.LastRow(); r++) {
                            mySheetEquip.SetCellValue(r, "webYn", 1);
                            mySheetEquip.SetCellValue(r, "featuredYn", 1);
                        }
                    }
                } else {
                	//기능수정 #903에 의해 문서(Document_PDF_20161221.pptx) Page 16에 의해 주석처리함(2016.12.26)
                	/*
                    mySheetEquip.SetColHidden("webYn", 1);
                    mySheetEquip.SetColHidden("featuredYn", 1);
                    */
                }

                offerPoTypeControl(); //-- Offer/Po Type Control.

                if($("#dealType").val() =="BUY"){
                    $("#offerType").val("SQ");
                }

                setFromTo();
                setHightRowPrice();

                break;
            case "dealType":
                offerPoTypeControl();
                setFromTo();
                setHightRowPrice();
                break;
            case "offerType":
            case "poType":
            case "cntrType":
            case "invoiceType":
                setFromTo();
                setHightRowPrice();

                break;
            case "currency":
            	change_currency();
                break;
            case "exDate":
                getExRate();
                break;
        }

    }

    function getExRate() {
        var strCurrency = document.getElementById('currency').value;
        var strExDate = document.getElementById('exDate').value;
        var strExRate = 0;
        if (strExDate != "" && strCurrency != "") {
            var params = {exCurr : strCurrency, exDate : strExDate, exRate : strExRate};
            ComCallAjaxUrl('getExchangeRateCall.do', params, getExchangeRateCall);
        }
    }

    function setFromTo() {

        if($("#dealType").val()=="BUY" || $("#dealType").val()=="REFURB") {
            if ($("#docTitle").val() == "QUOTE") {
                if ($("#offerType").val() == "SQ" || $("#offerType").val() == "PQ") {
                    $("#cidDiv1").html(tmCidDiv2Html);
                    $("#displayDiv1").html(tmpDisplayDiv2Html);
                    $("#personDiv1").html(tmpPersonDiv2Html);
                    $("#personDisplayDiv1").html(tmpPersonDisplayDiv2Html);
                    $("#cidDiv2").html(tmCidDiv1Html);
                    $("#displayDiv2").html(tmpDisplayDiv1Html);
                    $("#personDiv2").html(tmpPersonDiv1Html);
                    $("#personDisplayDiv2").html(tmpPersonDisplayDiv1Html);
                } else {
                    $("#cidDiv1").html(tmCidDiv1Html);
                    $("#displayDiv1").html(tmpDisplayDiv1Html);
                    $("#personDiv1").html(tmpPersonDiv1Html);
                    $("#personDisplayDiv1").html(tmpPersonDisplayDiv1Html);
                    $("#cidDiv2").html(tmCidDiv2Html);
                    $("#displayDiv2").html(tmpDisplayDiv2Html);
                    $("#personDiv2").html(tmpPersonDiv2Html);
                    $("#personDisplayDiv2").html(tmpPersonDisplayDiv2Html);
                }
            } else {

                if ($("#docTitle").val() == "PO" || $("#docTitle").val() == "CNTR") {
                    $("#cidDiv1").html(tmCidDiv1Html);
                    $("#displayDiv1").html(tmpDisplayDiv1Html);
                    $("#personDiv1").html(tmpPersonDiv1Html);
                    $("#personDisplayDiv1").html(tmpPersonDisplayDiv1Html);
                    $("#cidDiv2").html(tmCidDiv2Html);
                    $("#displayDiv2").html(tmpDisplayDiv2Html);
                    $("#personDiv2").html(tmpPersonDiv2Html);
                    $("#personDisplayDiv2").html(tmpPersonDisplayDiv2Html);
                } else if ($("#docTitle").val() == "INV") {
                    $("#cidDiv1").html(tmCidDiv2Html);
                    $("#displayDiv1").html(tmpDisplayDiv2Html);
                    $("#personDiv1").html(tmpPersonDiv2Html);
                    $("#personDisplayDiv1").html(tmpPersonDisplayDiv2Html);
                    $("#cidDiv2").html(tmCidDiv1Html);
                    $("#displayDiv2").html(tmpDisplayDiv1Html);
                    $("#personDiv2").html(tmpPersonDiv1Html);
                    $("#personDisplayDiv2").html(tmpPersonDisplayDiv1Html);
                }

            }

        } else {
            if($("#docTitle").val() == "QUOTE" || $("#docTitle").val() == "INV" || ($("#docTitle").val() == "PO" && offerTypeOrg == "BQ")) {    //Quote|Invoce|PO(이고 이전 문서가 Buy Quote인 경우) 일때
                $("#cidDiv1").html(tmCidDiv2Html);
                $("#displayDiv1").html(tmpDisplayDiv2Html);
                $("#personDiv1").html(tmpPersonDiv2Html);
                $("#personDisplayDiv1").html(tmpPersonDisplayDiv2Html);
                $("#cidDiv2").html(tmCidDiv1Html);
                $("#displayDiv2").html(tmpDisplayDiv1Html);
                $("#personDiv2").html(tmpPersonDiv1Html);
                $("#personDisplayDiv2").html(tmpPersonDisplayDiv1Html);
            } else {
                $("#cidDiv1").html(tmCidDiv1Html);
                $("#displayDiv1").html(tmpDisplayDiv1Html);
                $("#personDiv1").html(tmpPersonDiv1Html);
                $("#personDisplayDiv1").html(tmpPersonDisplayDiv1Html);
                $("#cidDiv2").html(tmCidDiv2Html);
                $("#displayDiv2").html(tmpDisplayDiv2Html);
                $("#personDiv2").html(tmpPersonDiv2Html);
                $("#personDisplayDiv2").html(tmpPersonDisplayDiv2Html);
            }
        }

        var myForm = document.Frm;

        if (mySheet.LastRow() > 0) {
            myForm.buyCompId.value = mySheet.GetCellValue(1, "buyCompId");
            myForm.buyCompNm.value = mySheet.GetCellValue(1, "buyCompNm");
            myForm.docBuyCompNm.value = mySheet.GetCellValue(1, "docBuyCompNm");
            myForm.fromPicPersonId.value = mySheet.GetCellValue(1, "fromPicPersonId");
            myForm.fromPicPersonNm.value = mySheet.GetCellValue(1, "fromPicPersonNm");
            myForm.docFromPicPersonNm.value = mySheet.GetCellValue(1, "docFromPicPersonNm");

            myForm.sellCompId.value = mySheet.GetCellValue(1, "sellCompId");
            myForm.sellCompNm.value = mySheet.GetCellValue(1, "sellCompNm");
            myForm.docSellCompNm.value = mySheet.GetCellValue(1, "docSellCompNm");
            myForm.picPersonId.value = mySheet.GetCellValue(1, "picPersonId");
            myForm.picPersonNm.value = mySheet.GetCellValue(1, "picPersonNm");
            myForm.docPicPersonNm.value = mySheet.GetCellValue(1, "docPicPersonNm");
        }

        if($("#dealType").val()=="BUY") {

            if($("#buyCompId").val()=="") {
                $("#buyCompId").val("<%=session.getAttribute("compId")%>");
            }
            if($("#buyCompNm").val()=="") {
                $("#buyCompNm").val("<%=session.getAttribute("companyNm")%>");
            }
            if($("#fromPicPersonId").val()=="") {
                $("#fromPicPersonId").val("<%=session.getAttribute("userId")%>");
            }
            if($("#fromPicPersonNm").val()=="") {
                $("#fromPicPersonNm").val("<%=session.getAttribute("userNm")%>");
            }

        } else {

            if($("#sellCompId").val()=="") {
                $("#sellCompId").val("<%=session.getAttribute("compId")%>");
            }
            if($("#sellCompNm").val()=="") {
                $("#sellCompNm").val("<%=session.getAttribute("companyNm")%>");
            }
            if($("#picPersonId").val()=="") {
                $("#picPersonId").val("<%=session.getAttribute("userId")%>");
            }
            if($("#picPersonNm").val()=="") {
                $("#picPersonNm").val("<%=session.getAttribute("userNm")%>");
            }
        }
    }

    function setHightRowPrice() {

        if ($("#docTitle").val() == "QUOTE" && $("#offerType").val() == "MQ") {
            $("#equipLowAmountDiv").show();
            $("#equipHighAmountDiv").show();

            mySheetEquip.SetColHidden("equipLowMarketPrice", 0);
            mySheetEquip.SetColHidden("equipHighMarketPrice", 0);

        } else {
            $("#equipLowAmountDiv").hide();
            $("#equipHighAmountDiv").hide();

            mySheetEquip.SetColHidden("equipLowMarketPrice", 1);
            mySheetEquip.SetColHidden("equipHighMarketPrice", 1);
        }

        if ($("#docTitle").val() == "QUOTE" && $("#dealType").val() == "SELL") {
            $("#subPriorSalesYnDiv").show();

            if ($("#subPriorSalesYn").val() == "" || $("#subPriorSalesYn").val() == null) {
                $("#subPriorSalesYn").val("Y");
            }
        } else {
            $("#subPriorSalesYnDiv").hide();
            $("#subPriorSalesYn").val("");
        }
    }

    /*------------------------------------------------------------------------
     *  Event : getExchangeRateCall
     *  Desc. : ExchangeDate수정 시, ExchangeRate가져오기
     *------------------------------------------------------------------------*/
    function getExchangeRateCall(data) {
        $(data).each(function(index, data) {
            //var iCode = Number(data.code);
            var strCurrency = data.strCurrency;
            var strExDate = data.strExDate;
            var strExRate = data.strExRate;

            //if(iCode == 1){
            document.getElementById('exRate').value = strExRate;

        });
    }

    /*------------------------------------------------------------------------
     *  Event : getCategoryCall
     *  Desc. : Temp Model수정 시, Category가져오기
     *------------------------------------------------------------------------*/
    function getCategoryCall(data) {
        $(data).each(function(index, data) {
            //var iCode = Number(data.code);
            var strStandardMaker = data.strStandardMaker;
            var compNm = data.compNm;
            var strStandardModel = data.strStandardModel;
            var modelNm = data.modelNm;
            var strCategoryGrp = data.strCategoryGrp;
            var strCategoryCd = data.strCategoryCd;

            mySheetEquip.SetCellValue(mySheetEquip.GetSelectRow(), "standardMaker ", strStandardMaker);
            mySheetEquip.SetCellValue(mySheetEquip.GetSelectRow(), "makerNm", compNm);
            mySheetEquip.SetCellValue(mySheetEquip.GetSelectRow(), "maker", compNm);
            mySheetEquip.SetCellValue(mySheetEquip.GetSelectRow(), "standardModel ", strStandardModel);
            mySheetEquip.SetCellValue(mySheetEquip.GetSelectRow(), "modelNm", modelNm);
            mySheetEquip.SetCellValue(mySheetEquip.GetSelectRow(), "categoryGrp", strCategoryGrp);
            mySheetEquip.SetCellValue(mySheetEquip.GetSelectRow(), "categoryCd", strCategoryCd);

        });
    }
    
    //첨부ID가져오기(채번)
    function getAttaGrpId(){
    	
    	var result = '';
        $.ajax({
			type : 'POST',
			url : 'getAttaGrpId.do',
			data : '',
			dataType : "json",
			async : false,
			success : function(data) {
				
				if (data){
					result = data.Data;
				}
			},
			error : function(e) {
				alert('<spring:message code="message.error"/>');
			}
		});
        
        return result;
    }
    //공통코드조회    
    function getCommonCode(groupCode, callbackFn){
	 	$.ajax({	//공통코드 일과 가져오기(isCache:캐시사용여부)
			type : 'POST',
			url : 'getComCode.do',
			data : 'isCache=N&grp_cd=' + groupCode,
			dataType : "json",
			async : true,
			success : function(result) {					
				if (result.Data){
					callbackFn(result.Data);
				}
				else{
					callbackFn(null);
				}
			},
			error : function(e) {
				alert('<spring:message code="message.error"/>');
			}
		});
    }

    /*------------------------------------------------------------------------
     *  Event : Validation(Row, Col, Value)
     *  Desc. : 저장 전 Validation Check
     *------------------------------------------------------------------------*/
    //-- Deal Validation.
    function Frm_Validation() {
        Result = "Success";
        //--------------------------------------
        //-- 필수항목 체크

        if (document.getElementById('docTitle').value == "") {
            alert("<spring:message code="message.save.fail.documentType"/>");
            document.getElementById('docTitle').focus();
            Result = "Fail";
            return;
        }

        if (document.getElementById('docSubj').value == "") {
            alert("<spring:message code="message.save.fail.docsubj"/>");
            document.getElementById('docSubj').focus();
            Result = "Fail";
            return;
        }

        if (document.getElementById('stageDate').value == "") {
            alert("<spring:message code="message.save.fail.docdate"/>");
            document.getElementById('stageDate').focus();
            Result = "Fail";
            return;
        }

      	//결함 #760에 의해서 SELL, QUOTE이고 TOOL_PRICE인것이 있으면 Validity가 필수로 바뀜. at 1 dec 2016)
        if($("#dealType").val() == "SELL" && $('#docTitle').val() == 'QUOTE') {
            var toolPriceCnt = 0;
            var equipCnt = mySheetEquip.LastRow() - 1;
            for (var r = 1; r <= equipCnt; r++) {
	            if (mySheetEquip.GetCellValue(r, "status") != "D") {
		            var thisSubjectCd = mySheetEquip.GetCellValue(r, "subject");
		            if (thisSubjectCd == 'TOOL_PRICE'){
		                toolPriceCnt++;
		            }
	        	}
            }
            
        	if (toolPriceCnt > 0 && document.getElementById('valDate').value == "") {
                alert("<spring:message code="message.save.fail.valdate"/>");
                document.getElementById('valDate').focus();
                Result = "Fail";
                return;
            }
        }

        if (document.getElementById('exDate').value == "") {
            alert("<spring:message code="message.save.fail.exchangeDt"/>");
            document.getElementById('exDate').focus();
            Result = "Fail";
            return;
        }

        if ($("#buyCompId").val() == $("#sellCompId").val()) {
            alert("<spring:message code="message.sp.cannotinputsamecomp"/>");
            $("#buyCompId").focus();
            Result = "Fail";
            return;
        }

    }

    //-- Equip Validation.
    function Equip_Validation() {
        Result = "Success";
        //--------------------------------------
        //-- 필수항목 체크
        var chkItem = "";
        //alert("mySheetEquip.LastRow() ====>"+mySheetEquip.LastRow());
        var equipCnt = mySheetEquip.LastRow() - 1;
        var equipchk = "";
        var subjectchk = "";

        for (var r = 1; r <= equipCnt; r++) {

            if (mySheetEquip.GetCellValue(r, "status") != "D") {

                //-- Category
               	//기능수정 #903에 의해 문서(Document_PDF_20161221.pptx) Page 16에 의해 Category1이 없어지고 아래 코드로 변경함(2016.12.26)
                //if (mySheetEquip.GetCellValue(r, "categoryGrp") == "" || mySheetEquip.GetCellValue(r, "categoryCd") == "") {
                if (mySheetEquip.GetCellValue(r, "categoryCd") == "") {
                
                    chkItem = "Category";
                    Result = "Fail";
                    break;
                }

                //-- Maker
                if (mySheetEquip.GetCellValue(r, "maker") == "") {
                    chkItem = "Maker";
                    Result = "Fail";
                    break;
                }

                //-- Model
                if (mySheetEquip.GetCellValue(r, "model") == "") {
                    chkItem = "Model";
                    Result = "Fail";
                    break;
                }

                //-- Subject
                if (mySheetEquip.GetCellValue(r, "subject") == "") {
                    chkItem = "Subject";
                    Result = "Fail";
                    break;
                }

                //-- UnitPrice
/*                 if (mySheetEquip.GetCellValue(r, "unitPrice") < 1) {
                    chkItem = "Unit Price";
                    Result = "Fail";
                    break;
                } */
                
                //-- Oppt에 입력된 장비만 등록가능.
                if (mySheetEquip.GetCellValue(r, "opptId") < 1) {
	                chkItem = "["+ r +"] Oppt Id";
	                Result = "Fail_Equip";
	                alert("Equipment List (" + chkItem + "): <spring:message code="message.save.fail.onlywtbwts"/>");
	                break;
                }

                //-- Payment Id
                //-- 다른 PO등에 의해 payment가 이미 생성되었으므로, 해당 Equip.은 삭제처리후 저장.
                /* 2016-12-07, Watney, John요청에 의해 제약조건 제거함
                if (document.getElementById("docTitle").value == "QUOTE" || document.getElementById("docTitle").value == "PO") {
                    equipchk = mySheetEquip.GetCellValue(r, "eId");
                    subjectchk = mySheetEquip.GetCellValue(r, "subject");
                    if (mySheetEquip.GetCellValue(r, "paymentId") != "") {
                        chkItem = "Payment Id";
                        Result = "Fail_Payment";
                        alert(equipchk + " : <spring:message code="message.save.fail.existpayment"/>");
                        break;
                    }
                }
                */

                //-- Standard Maker/Model Check.
                //-- eId가 없는 경우는 로직에 의해 eId가 신규로 생성되므로, 저장시 체크
                //-- 이미 저장된 경우, eId가 존재하므로 그 건에 대해서만 미리 체크
                if (mySheetEquip.GetCellValue(r, "eId") != "New") {
                    if (mySheetEquip.GetCellValue(r, "standardMaker") == "" || mySheetEquip.GetCellValue(r, "standardModel") == "") {
                        chkItem = "Standard Maker/Model";
                        Result = "Fail";
                        break;
                    }
                }

            } //-- if(mySheetEquip.GetCellValue(r,"status")!="D"){

            //-- Dup Check.
            if (equipchk != "New") {
                for (var k = r + 1; k <= equipCnt; k++) {
                    if (mySheetEquip.GetCellValue(k, "eId") == equipchk && mySheetEquip.GetCellValue(k, "subject") == subjectchk) {
                        //-- 동일한 EID가 존재시
                        alert(equipchk + " : <spring:message code="message.check.null.dupcode"/>");
                        Result = "Fail_Equip";
                        break;
                    }
                }
            }
            
            //issue-request-No.685 : Deal Drop된 장비 대상으로 Tool Price 문서 생성 불가, 용역 문서 생성 가능 요청에 의해 기능추가
            var thisSubjectCd = mySheetEquip.GetCellValue(r, "subject");
            var thisDealStatusCd = mySheetEquip.GetCellValue(r, "equipDealStatusCd");
            if (thisSubjectCd == 'TOOL_PRICE' && thisDealStatusCd == 'DROP'){
                alert("<spring:message code="message.sp.cannottoolprice"/>");   //Deal Drop된 장비 대상으로 Tool Price 문서 생성 불가합니다
                Result = "Fail_Equip";
                break;
            }

        }//-- for...end.

        if (Result == "Fail") {
            alert("Equipment List [" + chkItem + "] <spring:message code="message.sp.rowisrequired"/>");
        }
    }
        

    //-- Pay Validation.
    function Pay_Validation() {
        Result = "Success";
        //--------------------------------------
        //-- 필수항목 체크
        var chkItem = "";
        //alert("mySheetPay.LastRow() ====>"+mySheetPay.LastRow());
        var payCnt = mySheetPay.LastRow() - 1;
        for (var r = 1; r <= payCnt; r++) {

            if (mySheetPay.GetCellValue(r, "status") != "D") {
                //-- Rate 기능수정 #903에 의해 문서(Document_PDF_20161221.pptx) Page 19에 의해 삭제됨(2016.12.26)
                /* if (mySheetPay.GetCellValue(r, "pmtTermsRate") == "") {
                    chkItem = "Rate";
                    Result = "Fail";
                    break;
                } */

                //0보다 작은 경우 처리해달라고 현업(Allie,..)에서 요청 이부분 제거(2017.1.18)
                //-- Value 기능수정 #903에 의해 문서(Document_PDF_20161221.pptx) Page 19에 의해 Amount로 변경됨(2016.12.26)
/*                 if (mySheetPay.GetCellValue(r, "pmtTermsAmt") < 1) {
                    chkItem = "Amount";
                    Result = "Fail";
                    break;
                } */
                

                //-- Method
                if (mySheetPay.GetCellValue(r, "pmtTermsMethod") == "") {
                    chkItem = "Method";
                    Result = "Fail";
                    break;
                }

                //-- Timing
                if (mySheetPay.GetCellValue(r, "pmtTermsTiming") == "") {
                    chkItem = "Timing";
                    Result = "Fail";
                    break;
                }

                //기능수정 #903에 의해 문서(Document_PDF_20161221.pptx) Page 19에 의해 PO, Contract일때만 필수로 변경됨(2016.12.26)
                if ($("#docTitle").val() == "PO" || $("#docTitle").val() == "CNTR"){
	                if (mySheetPay.GetCellValue(r, "pmtDueDt") == "") {
	                    chkItem = "Due Date";
	                    Result = "Fail";
	                    break;
	                }
                }

            } //-- if(mySheetPay.GetCellValue(r,"status")!="D"){

        } //-- for...end.

        if (Result == "Fail") {
            alert("Payment Terms [" + chkItem + "] <spring:message code="message.sp.rowisrequired"/>");
        }

    }
    //PDF조회시
    function PDF_ViewValidation(noAlert){
    	Result = "Success";
 	 	var remainAmount = $('#pdfRemainAmount').text();
 	 	if (remainAmount != "0"){
 	 		Result = "Fail";
 	 		if (noAlert){
 	 			return {result:"false", msg:"The amount does not match the PDF"};
 	 		}
 	 		else{
 	 			alert("The amount does not match the PDF");	
 	 		}
 	 	}
 	 	return {result:"true", msg:""};
    }
    //저장시
    function PDF_Validation(noAlert){
    	Result = "Success";
 	 	
 	 	var chkItem = "";
        var cnt = mySheetPdf.LastRow() - 1;
        for (var r = 1; r <= cnt; r++) {

            if (mySheetPdf.GetCellValue(r, "status") != "D") {
                //-- Desc
                if (mySheetPdf.GetCellValue(r, "pdfDesc") == "") {
                    chkItem = "Description";
                    Result = "Fail";
                    break;
                }

                //-- Amount
                if (mySheetPdf.GetCellValue(r, "amt") == "") {
                    chkItem = "Amount";
                    Result = "Fail";
                    break;
                }

            }

        } //-- for...end.

        if (Result == "Fail") {
 	 		if (noAlert){
 	 			return {result:"false", msg:"Package PDF [" + chkItem + "] <spring:message code="message.sp.rowisrequired"/>"};
 	 		}
 	 		else{
 	 			alert("Package PDF [" + chkItem + "] <spring:message code="message.sp.rowisrequired"/>");	
 	 		}
        }
        
        return {result:"true", msg:""};
    }
    
	//PDF에 입력해야 할 남은금액 표시
    function SetRemainAmount(){
		var rows = mySheetEquip.FindCheckedRow("pdfYn");
		var checkedAmount = 0;
		$(rows.split('|')).each(function(idx, e){
			if (e){
				checkedAmount += mySheetEquip.GetCellValue(e, "unitPrice");
			}
		});
 	 	var remainAmount = roundXL((mySheetEquip.GetSumValue(0, "sumAmt") - checkedAmount) - mySheetPdf.GetSumValue(0, "sumAmt"), 2);
 	 	 	 	
 	 	$('#pdfRemainAmount').text(commify(remainAmount));
    }

    function setAmount() {

        var equipTotAmount = 0.0;
        var equipLowAmount = 0;
        var equipHighAmount = 0;
/*
        equipCnt = mySheetEquip.LastRow() - 1;

        for (var r = 1; r <= equipCnt; r++) {

            if (mySheetEquip.GetCellValue(r, "status") != "D") {
                equipTotAmount += mySheetEquip.GetCellValue(r, 'sumUnitPrice');
                equipLowAmount += mySheetEquip.GetCellValue(r, 'sumEquipLowMarketPrice');
                equipHighAmount += mySheetEquip.GetCellValue(r, 'sumEquipHighMarketPrice');
            }
        }
        */

        //위에 Loop주석 + 속도개선
        equipTotAmount = mySheetEquip.GetSumValue(0, "sumAmt");
        equipLowAmount = mySheetEquip.GetSumValue(0, "sumEquipLowMarketPrice");
        equipHighAmount = mySheetEquip.GetSumValue(0, "sumEquipHighMarketPrice");

        var val = roundXL(equipTotAmount, 6);
        $("#equipAmount").val(commify(val));
        $("#equipLowAmount").val(commify(equipLowAmount.toString()));
        $("#equipHighAmount").val(commify(equipHighAmount.toString()));
    }
     

    /*------------------------------------------------------------------------
     *  Event : payTermsTotal
     *  Desc. : Payment Terms의 총합 체크
     *------------------------------------------------------------------------*/
    function payTermsTotal() {
        Result = "Success";

        //var valueSum = mySheetPay.ComputeSum("|pmtTermsAmt|");
        //var unitPriceSum = mySheetEquip.ComputeSum("|unitPrice|");
        var valueSum = mySheetPay.GetSumValue(0, "sumAmt");
        var unitPriceSum = mySheetEquip.GetSumValue(0, "sumAmt");
        //alert(valueSum);
        //alert(unitPriceSum);

        if (valueSum != unitPriceSum) {
            alert("<spring:message code="message.save.fail.equalvalue"/>");
            Result = "Fail";
        }
        return;
    }

    /*------------------------------------------------------------------------
     *  Event : view(data)
     *  Desc. : Visible
     *------------------------------------------------------------------------*/
    //-- 각 IbSheet Visible
    function view(obj) {
        var visible = document.getElementById(obj);
        if (visible.style.display != 'none') {
            visible.style.display = 'none'; // visible -> none
        } else {
            visible.style.display = ''; // none -> visible
        }
    }

    //-- AttachFiles Visible
    function viewAttachFiles(data) {
        //-- 파일첨부 Visible
        return;
        if (document.getElementById('docId').value == "") {
            document.getElementById('fileAttach').style.display = 'none'; // visible -> none;
        } else {
            document.getElementById('fileAttach').style.display = ''; // none -> visible;
        }
    }


    /*------------------------------------------------------------------------
     *  Event : IdClear()
     *  Desc. : Doc Title 변경 시, 신규생성 및 관련 Deal Set.
     *------------------------------------------------------------------------*/
    function IdClear() {

        //-- Doc. 신규생성.
        if (docTitleOrg != document.getElementById('docTitle').value) {
            //-- Mapping
            /* if ((document.getElementById("docTitle").value == "QUOTE" && relIdOrg != "") || (document.getElementById("docTitle").value == "PO" && docTitleOrg != "QUOTE") || (document.getElementById("docTitle").value == "INV" && docTitleOrg != "PO")) {
                if (docIdOrg == "" && relIdOrg == "") {
                    //-- Relation 없이 최초 등록인 경우는 모든 Stage 등록 가능.
                } else {
                    //-- 이전 Stage등록 체크
                    alert("<spring:message code="message.save.fail.stage"/>");
                    //-- 조회시의 상태로 Set.
                    document.getElementById('docTitle').value = docTitleOrg;
                    document.getElementById('docId').value = docIdOrg;
                    document.getElementById('relId').value = relIdOrg;
                    document.getElementById("equipAmount").value = equipAmountOrg;
                }
            } else { */
                document.getElementById('docId').value = '';
            	document.getElementById('customerDocId').value = '';
            	//approvalStatusCd
                if (docIdOrg != "0" && docIdOrg != "") {
                    document.getElementById('relId').value = docIdOrg;
                }
                document.getElementById("equipAmount").value = 0;
            //}
        } else {
            //----------------------------------------------
            //-- 원래의 Document ID로 복원.
            document.getElementById('docId').value = docIdOrg;
            document.getElementById('customerDocId').value = docIdOrg;
            document.getElementById('relId').value = relIdOrg;
            document.getElementById("equipAmount").value = equipAmountOrg;
        }

        //-- 파일첨부 Visible
        viewAttachFiles();

      	//외부에서나 Deal에서 왔을때는 최초저장 전까지 수행되지 않아야 하며 , 문서에서 전환하려는 경우는 동작해야한다
        if ("${selEquip}" == "" || !isNotFirstSave){        	
        	doAction("SearchEquip");
            //doAction("SearchPay");	Equip조회후에 읽히도록 동기로 이동해야 해서 주석!            
        }
      	//다시 원본으로 왔을때는 조회한다(문서이동시에는 유지하기위해 조회안함)
      	if ($('#docId').val() != ''){
	        doAction("SearchPdf");
	        doAction("SearchPdfCol");
      	}
        //-- Equip. Search
        
    }

    /*------------------------------------------------------------------------
     *  Event : paramXXDate(date)
     *  Desc. : Date Set.
     *------------------------------------------------------------------------*/
    function setStageDate(date) {
        document.getElementById('stageDate').value = date;
    }

    function setValDate(date) {
        document.getElementById('valDate').value = date;
    }

    function setWarLaborDt(date) {
        document.getElementById('warLaborDt').value = date;
    }

    function setWarPartDt(date) {
        document.getElementById('warPartDt').value = date;
    }

    function setExDate(date) {
        document.getElementById('exDate').value = date;
        onChange('exDate');
    }
     
     <%--------------------------------------------------------------------------
     ####### Tree : Event Function ################################
     ---------------------------------------------------------------------------%>
     function mySheetTree_OnSearchEnd(Code, Msg, StCode, StMsg) {
         var R = "FF0000"; /* 결재할 대상 */
         var G = "0011FF"; /* 결재 완료 대상 */
         var B = "000000"; /* */
         
         var delNumArr = [];

         for (var i = 1; i <= mySheetTree.LastRow(); i++) {
             var code = mySheetTree.GetCellValue(i, "code");
             var parentCd = mySheetTree.GetCellValue(i, "parentCd");

             if (mySheetTree.GetCellValue(i, "openYn") == "Y") {
                 if(code == "SAAC" || code == "RFBT" ||  code == parentCd ){
                     mySheetTree.SetDataLinkMouse("codeNm", 1);
                     
                     var fontColor = mySheetTree.GetCellValue(i, "color");
                     if(fontColor != "B"){
                      mySheetTree.SetRowFontColor(i, eval(fontColor));
                   }
                    mySheetTree.SetCellFontUnderline(i, "codeNm", 1);
                 }
             }
             if(mySheetTree.GetCellValue(i,"selectYn")=="V") {
                 mySheetTree.SetCellFontBold(i, "codeNm", 1);
                mySheetTree.SetCellFontUnderline(i, "codeNm", 0);
                mySheetTree.SetRowBackColor(i,"#F0FFE2");
             }
         }
     }    

     function mySheetTree_OnMouseMove(Button, Shift, X, Y) {
        //마우스 위치를 행과 컬럼과 값 가져오기
        var Row = mySheetTree.MouseRow();
        var Col = mySheetTree.MouseCol();
        //데이터 SaveName을 읽어옴
        var sText = "";
        var tooltip = false;

        var sSaveName = mySheetTree.GetCellProperty(Row, Col, "SaveName");
        if (sSaveName == "codeNm") {
            var code = mySheetTree.GetCellValue(Row, "code");
             var parentCd = mySheetTree.GetCellValue(Row, "parentCd");
            if (mySheetTree.GetCellValue(Row, "openYn") == "Y") {
                 if(code == parentCd ){
                     tooltip = true;
                 sText = mySheetTree.GetCellText(Row, "codeNm");
                 } 
            } 
        }

        if(tooltip){
            mySheetTree.ShowToolTip(1);
        } else{
            mySheetTree.ShowToolTip(0);
        }

       mySheetTree.SetToolTipText(Row, Col, sText);
     }
     
     /* function mySheetTree_OnResize(width, height) {
         $(".GridMain2").height(0);
     } */
     
     function mySheetTree_OnClick(Row, Col, Value, CellX, CellY, CellW, CellH) {
         //-- 특정 열을 클릭했을 때 해당 페이지로 이동하도록 처리
         //-- 화면 오픈여부(openYn)='Y' 일때만 화면 연결
         if (mySheetTree.ColSaveName(Col) != "codeNm" || mySheetTree.GetCellValue(Row, "openYn") != "Y")
             return;
         var param = "";
         var dealTypeCd = $("#dealType").val();

         switch (mySheetTree.GetCellValue(Row, "parentCd")) {
            case "1LV":
                if(mySheetTree.GetCellValue(Row, "cnt") >= 1){                   
                    var codeArray = mySheetTree.GetCellValue(Row, "selectKey").split(",");
                      //detail
                      if(codeArray.length == 1) {
                          //DocList
                             switch (mySheetTree.GetCellValue(Row, "code")){
                              case "SAAC" :
                                  //alert("make link to ready!!");
                                  break;
                           }
                      } else {
                          switch (mySheetTree.GetCellValue(Row, "code")){
                             case "SAAC" :
                                 //alert("make link to ready!!");
                                 break;
                        }
                      }   
                 }
               break;
            case "VALU" :
                if("${valuId}V${valuVerId}" != mySheetTree.GetCellValue(Row, "selectKey")){
                    var selectKey = mySheetTree.GetCellValue(Row, "selectKey");
                    var vIdx = selectKey.indexOf('V',3);
                    var paramValuId = selectKey.substr(0, vIdx);
                    var paramValuVerId = selectKey.substr(vIdx+1);

                    param = "&valuId=" + paramValuId+"&valuVerId="+paramValuVerId+"&treeType="+dealTypeCd;                    
                    parent.func_maincall("viewValuation.do", "Valuation", "VA", "Valuation", param);
                }
              break;
            case "INSP" :
               param = "&createFlag=U&inspId=" + mySheetTree.GetCellValue(Row, "selectKey")+"&treeType="+dealTypeCd;
                 parent.func_maincall("IN0200M.do", "Inspection", "IN", "Inspection", param);
                 break;   
             case "WTB_WTS":
                 param = "&Id=" + mySheetTree.GetCellValue(Row, "selectKey") + "&relId=" + mySheetTree.GetCellValue(Row, "relId");
                 if (mySheetTree.GetCellValue(Row, "type") == "REFURB") {
                     parent.func_maincall("SP0600M.do", "Refub Deal ", "", "Refub Deal ", param);
                 } else {
                     parent.func_maincall("SP0200M.do", "WTB/WTS ", "", "WTB/WTS ", param);
                 }
                 break;
               
             case "OPPT":
                param = "&Id=" + mySheetTree.GetCellValue(Row, "selectKey") + "&relId=" + mySheetTree.GetCellValue(Row, "relId");
                if (mySheetTree.GetCellValue(Row, "type") == "REFURB") {
                    parent.func_maincall("SP0600M.do", "Refub Deal ", "", "Refub Deal ", param);
                } else {
                    parent.func_maincall("SP0205M.do", "WTB/WTS ", "", "WTB/WTS ", param);
                }
                break;
            case "QT":
            case "BQ":
            case "SQ":
            case "PQ":
            case "RQ":
            case "MQ":
            case "FQ":
            /*Document*/
            case "PO":
            case "CT":
            case "MC":
            case "RC":
            case "IV":
            case "RI":
                if(mySheetTree.GetCellValue(Row, "code") == mySheetTree.GetCellValue(Row, "parentCd")){
                    if(mySheetTree.GetCellValue(Row, "relId") != ""){
                        if(mySheetTree.GetCellValue(Row, "selectKey")!=null && mySheetTree.GetCellValue(Row, "selectKey")!="") {
                            param = "&relId=&docId=" + mySheetTree.GetCellValue(Row, "selectKey");
                            parent.func_maincall("SP0300M.do", "Offer/PO/Cont/Inv ", "", "Offer/PO/Cont/Inv ", param);
                        }
                    }
                }
                break;
            /*Shipment*/    
            case "FABI" :
            case "FABO" :
                param = "&createFlag=U&paramDdfpId=" + mySheetTree.GetCellValue(Row, "selectKey");
                parent.func_maincall("LO0110M.do", "Logistics > FAB-Out ", "LO0100M", "FAB-Out", param);
                break;
           case "MOVI" :
           case "MOVO" :
               param = "&createFlag=U&moveId=" + mySheetTree.GetCellValue(Row, "selectKey");
               parent.func_maincall("LO0210M.do", "Logistics > Logistics List ", "LO0200M", "Logistics > Logistics ", param);
               break;
           case "PMTO" :
           case "PMTI" :
               var selectKey = mySheetTree.GetCellValue(Row, "selectKey");
               var sIdx = selectKey.indexOf('S');
               var paramId = selectKey.substr(0, sIdx);
               var paramSeq = selectKey.substr(sIdx+1);
               
               param = "&createFlag=U&paymentId=" + paramId +"&paySeq="+paramSeq+"&treeType="+dealTypeCd;
               parent.func_maincall("PA0200M.do", "Payment", "PA", "Payment ", param);
               break;
     
         }
     }

    /*------------------------------------------------------------------------
     *  Event : Popup(data)
     *  Desc. : 팝업화면
     *------------------------------------------------------------------------*/
    //-- Form PopUp
    function openPopup(data) {
        switch (data) {
            case "eId":
                //----------------------------------
                //-- Equipment List (Multi Select)
                //----------------------------------
                var myForm = document.popFrm;

                var url = "SP0242P.do";
                if ($("#opptId").val() != "") {
                    url = "SP0241P.do";
                }

                popWin = window.open("", "popFrm1", "toolbar=no, width=1250, height=650, directories=no, status=no, scrollorbars=no, resizable=no");
                popWin.onclose = function() {
                    popWin = null;
                };
                popWin.opened = true;

                myForm.action = url;
                myForm.method = "post";
                myForm.target = "popFrm1";
                myForm.PopGbn.value = "doc";
                myForm.searchId.value = $("#relId").val();
                myForm.DealType.value = $("#dealType").val();
                myForm.DocType.value = $("#docTitle").val();

                if ($("#docTitle").val() == "QUOTE") {
                    myForm.DocDetailType.value = $("#offerType").val();
                } else if ($("#docTitle").val() == "PO") {
                    myForm.DocDetailType.value = $("#poType").val();
                } else if ($("#docTitle").val() == "CNTR") {
                    myForm.DocDetailType.value = $("#cntrType").val();
                } else if ($("#docTitle").val() == "INV") {
                    myForm.DocDetailType.value = $("#invoiceType").val();
                }

                myForm.submit();
                break;

            case "RefurbSource":
                //----------------------------------
                //-- Refurb Source List
                //----------------------------------
                if (document.getElementById("docId").value == "") {
                    alert("<spring:message code="message.save.fail.docid"/>");
                } else {
                    var myForm = document.popFrm;
                    var url = "SP0160P.do";

                    popWin = window.open("", "popFrm2", "toolbar=no, width=600, height=600, directories=no, status=no, scrollorbars=no, resizable=no");
                    popWin.onclose = function() {
                        popWin = null;
                    };
                    popWin.opened = true;

                    myForm.action = url;
                    myForm.method = "post";
                    myForm.target = "popFrm2";
                    myForm.PopGbn.value = document.getElementById("docId").value; // data;
                    myForm.submit();
                }
                break;

            case "Buyer":
            case "Seller":
                //----------------------------------
                //-- Buyer/Seller Company
                //----------------------------------
                var myForm = document.popFrm;
                var url = "";
                if (data == "Buyer") {

                    document.getElementById("buyer").value = "";
                    document.getElementById("buyerNm").value = "";
                    url = "pop.CompListPopup.do?fileId=buyer&fileNm=buyerNm";
                } else if (data == "Seller") {

                    document.getElementById("seller").value = "";
                    document.getElementById("sellerNm").value = "";
                    url = "pop.CompListPopup.do?fileId=seller&fileNm=sellerNm";
                }
                popWin = window.open("", "popFrm3", "toolbar=no, width=700, height=600, directories=no, status=no, scrollorbars=no, resizable=no");
                popWin.onclose = function() {
                    popWin = null;
                };
                popWin.opened = true;

                myForm.action = url;
                myForm.method = "post";
                myForm.target = "popFrm3";
                myForm.PopGbn.value = "Form"; //-- Set Column구분(Grid/From)
                myForm.submit();
                break;

            case "sellCompId":

                cfn_companyListPopup("sellCompIdCallback", "", "Y");
                break;
            case "buyCompId":
                cfn_companyListPopup("buyCompIdCallback", "", "Y");
                break;

            case "picPersonId":
                //SG 본사 cid C18932, C22730, C20662, C19221

                if ($("#sellCompId").val() == "C18932" || $("#sellCompId").val() == "C22730" || $("#sellCompId").val() == "C20662" || $("#sellCompId").val() == "C19221") {
                    cfn_personListPopup("picPersonIdCallback", $("#sellCompId").val());
                } else {
                    cfn_accountListPopup("picPersonIdCallback", $("#sellCompId").val());
                }
                break;
            case "fromPicPersonId":
                //SG 본사 cid C18932, C22730, C20662, C19221

                if ($("#buyCompId").val() == "C18932" || $("#buyCompId").val() == "C22730" || $("#buyCompId").val() == "C20662" || $("#buyCompId").val() == "C19221") {
                    cfn_personListPopup("fromPicPersonIdCallback", $("#buyCompId").val());
                } else {
                    cfn_accountListPopup("fromPicPersonIdCallback", $("#buyCompId").val());
                }
                break;
            case "dispValuId":

                var myForm = document.popFrm;

                popWin = window.open(url, "popFrm4", "toolbar=no, width=650, height=500, directories=no, status=no, scrollbars=no, resizable=no");
                popWin.onclose = function() {
                    popWin = null;
                };
                popWin.opened = true;

                myForm.action = "SP0250P.do";
                myForm.method = "post";
                myForm.target = "popFrm4";

                var equipList = "";

                var equipCnt = mySheetEquip.LastRow() - 1;
                for (var r = 1; r <= equipCnt; r++) {

                    if (mySheetEquip.GetCellValue(r, "status") != "D") {
                        equipList += "," + mySheetEquip.GetCellValue(r, "eId") + mySheetEquip.GetCellValue(r, "equipTxCnt")
                    }
                }

                myForm.equipList.value = equipList.substring(1, equipList.length);
                myForm.submit();
                
                break;
            case "linkValuId":	//Valuation Link
            	
            	if ($('#dispValuId').val() != ''){
            		var url = "viewValuation.do?menucd=VA&fullpath=Valuation"
            		    + "&valuId=" + $("#valuId").val()
            			+ "&valuVerId=" + $("#valuVerId").val()
            			+ "&popUp=Y";
            		
            		var myForm = document.popFrm;
                    popWin = window.open("", "popFrm3", "toolbar=no, width=1400, height=700, directories=no, status=no, scrollbars=yes, resizable=yes");
                    popWin.onclose = function() {
                        popWin = null;
                    };
                    popWin.opened = true;
    
                    myForm.action = url;
                    myForm.method = "post";
                    myForm.target = "popFrm3";
                    myForm.PopGbn.value = "Form"; //-- Set Column구분(Grid/From)
                    myForm.submit();
                    break;
            	}
            	break;
        }
    }

    function sellCompIdCallback(data) {
        $("#personId").val("");
        $("#picPersonNm").val("");
        $("#docSellCompNm").val("");
        $("#docPicPersonNm").val("");

        $("#sellCompId").val(data.compId);
        $("#sellCompNm").val(data.compNm);
        $("#docSellCompNm").val(data.compNm);
    }

    //From(CID) Popup Callback
    function buyCompIdCallback(data) {
        $("#fromPicPersonId").val("");
        $("#fromPicPersonNm").val("");
        $("#docBuyCompNm").val("");
        $("#docFromPicPersonNm").val("");

        $("#buyCompId").val(data.compId);
        $("#buyCompNm").val(data.compNm);
        $("#docBuyCompNm").val(data.compNm);

    }

    function picPersonIdCallback(data) {
        $("#picPersonId").val(data.personId);
        $("#picPersonNm").val((data.personNm == "" ? data.personLocalNm : data.personNm));
        $("#docPicPersonNm").val((data.personNm == "" ? data.personLocalNm : data.personNm));
    }

    function fromPicPersonIdCallback(data) {
        $("#fromPicPersonId").val(data.personId);
        $("#fromPicPersonNm").val((data.personNm == "" ? data.personLocalNm : data.personNm));
        $("#docFromPicPersonNm").val((data.personNm == "" ? data.personLocalNm : data.personNm));
    }

    //Valuation선택후 Callback(25 jan 2017)
    function selectedValuationCallback(e){
    	if (e){
            $("#dispValuId").val(e.dispValuId);
            $("#valuId").val(e.valuId);
            $("#valuVerId").val(e.valuVerId);
            
            //Header에 바로 저장한다
            if ($('#docId').val() != ''){
                var params = {docId:$('#docId').val()};
                ComCallAjaxUrl('SP0300MSaveValuation.do', params, function(data){
                    //화면에 반영할 부분 조회한다
                    //1. PDF View
                }); 
            }             
    	}
    }


    /*------------------------------------------------------------------------
     *  Event : selectEquipCount
     *  Desc. : Equipment를 선택한 것이 있는지 체크.
     *------------------------------------------------------------------------*/
    function selectEquipCount() {
        var dRows = mySheetEquip.FindCheckedRow("sel");
        if (dRows == "") {
            selEquipYn = "N";
            alert("<spring:message code="message.save.fail.noselectEquip"/>");
        } else {
            selEquipYn = "Y";
        }
    }
    
    
    //결재초기화
	function initApproval(){
    	if (firstView){	//최초만 호출
			initSheet_A();
			initApprDiv_A();
			setApprovalInfo(apprData);
    	}
    	else{	//docId가 바뀔때 마다 호출
    		isApprovalListOpen = false;
    		initApprDiv_A();
    		setApprovalInfo(apprDataEmpty);    		
    	}
    	approvalReady(true);
	}


    /*------------------------------------------------------------------------
     *  Event : fn_approvalBefore
     *  Desc. : 결재 요청, 결재 전 수행
     *          varResult Obejct 를 생성하여, result 와 msg 두개 변수를 입력하여 반환한다.
     *------------------------------------------------------------------------*/
    function fn_approvalBefore(mode) {

        //-- Result
        var varResult = new Object();
        varResult.result = "false"; // true/false

        //-- mode구분
        var strMode = "";

        //-- Y:Deal(WTBWTS,OPPT) / N:PO(QUOTE/PO/INV) 구분
        document.getElementById("dealYn").value = 'N';

        //-- Document ID가 없으면 결재처리 안됨.
        if (document.getElementById("docId").value == "") {
            varResult.result = "false"; // true/false
            varResult.msg = "<spring:message code="message.save.fail.docid"/>"; // 메시지
            return varResult;
        }
        
      	//결재요청시 PDF금액체크 요청에의해(2017.1.17)
        var result = PDF_ViewValidation(true);
        if (Result != "Success"){
        	autoAppResult = "N";
        	return result;
        }

        //-------------------------
        switch (mode) {
            case "request":
                strMode = "REQ";
                break;
            case "approval":
                strMode = "APP";
                break;
        }
        document.getElementById("strMode").value = strMode;

        if(mode=="approval_cancel") {
            $.ajax({type : 'POST', url : "BeforApprovalCancelCheck.do", data : FormQueryStringEnc(document.Frm, mySheet), dataType : "json", async : false, success : function(data) {

                var checkCnt = data;

                if(data==0) {
                  //-- SUCCESS
                    varResult.result = "true"; // true/false
                    varResult.msg = ""; // 메시지
                } else {
                    varResult.result = "false"; // true/false
                    varResult.msg = "You can't approval cancel because there's new equipment number"; // 메시지
                }

            }, error : function() {
                varResult.result = "false"; // true/false
                varResult.msg = "<spring:message code="message.error"/>"; // 메시지
            }});

            if (varResult.result != "true") {
                autoAppResult = "N";
                //alert(varResult.msg);
            }
        } else {

            //-------------------------------------------
            //-- Before Request/Approval Procedure Call.
            //-------------------------------------------
            $.ajax({type : 'POST', url : "BeforeReqApp.do", data : FormQueryStringEnc(document.Frm, mySheet), dataType : "json", async : false, success : function(data) {
                var result = data.split("/");
                for (var i = 0; i < result.length; i++) {
                    //-- result[0]:DealId , result[1]:Return Message
                    result[i];
                    //alert(result[i]);
                }

                if (typeof result[1] == "undefined") {
                    //-- SUCCESS
                    varResult.result = "true"; // true/false
                    varResult.msg = ""; // 메시지
                } else {
                    //-- ERROR
                    varResult.result = "false"; // true/false
                    varResult.msg = result[1]; // 메시지
                }
            }, error : function() {
                varResult.result = "false"; // true/false
                varResult.msg = "<spring:message code="message.error"/>"; // 메시지
            }});

            if (varResult.result != "true") {
                autoAppResult = "N";
                //alert(varResult.msg);
            }
        }
        return varResult;
    }

    /*------------------------------------------------------------------------
     *  Event : fn_approvalAfter
     *  Desc. : 결재요청, 결재 후 수행
     *          반환값은 없다.
     *------------------------------------------------------------------------*/
    function fn_approvalAfter(mode, type, approval_status) {

        //-- Result
        var varResult = new Object();
        varResult.result = "true"; // true/false
        
        $('#sellBnk').attr('disabled','disabled');  //결재관련후에는 비활성

        //alert("mode ===>"+mode)   ;
        //alert("type ===>"+type)   ;
        if (approval_status == "APPROVAL") {
            //-------------------------------------------
            //-- MM결재시에만 수행.
            //-------------------------------------------
            //-- mode구분
            var strMode = "";

            //-- Y:Deal(WTBWTS,OPPT) / N:PO(QUOTE/PO/INV) 구분
            document.getElementById("dealYn").value = 'N';

            //-- Document ID가 없으면 결재처리 안됨.
            if (document.getElementById("docId").value == "") {
                varResult.result = "false"; // true/false
                varResult.msg = "<spring:message code="message.save.fail.docid"/>"; // 메시지
                return varResult;
            }

            //-------------------------
            switch (mode) {
                case "request":
                    strMode = "REQ";
                    break;
                case "approval":
                    strMode = "APP";
                    break;
                case "AUTOPO":
                    strMode = "AUTOPO";
                    break;
            }
            document.getElementById("strMode").value = strMode;

            //-------------------------------------------
            //-- After Request/Approval Procedure Call.
            //-------------------------------------------
            $.ajax({type : 'POST', url : "AfterReqApp.do", data : FormQueryStringEnc(document.Frm, mySheet), dataType : "json", async : false, success : function(data) {
                var result = data.split("/");
                /*
                for (var i = 0; i < result.length; i++) {
                    //-- result[0]:DealId , result[1]:Return Message
                    result[i];
                    //alert(result[i]);
                }
                */

                if (typeof result[1] == "undefined") {
                    //-- SUCCESS
                    varResult.result = "true"; // true/false
                    //varResult.msg = ""; // 메시지
                } else {
                    //-- ERROR
                    varResult.result = "false"; // true/false
                    varResult.msg = result[1]; // 메시지
                }
            }, error : function(request, status, error) {				
	            varResult.result = "false"; // true/false
	            varResult.msg = "<spring:message code="message.error"/>" + "/n" + request.responseText; // 메시지
	            alert(varResult.msg);
        }});

        } else if (approval_status == "APPROVAL_CANCEL" || approval_status == "REJECT") {
            //Update
            $.ajax({type : 'POST', url : "AfterReqAppCancel.do", data : FormQueryStringEnc(document.Frm, mySheet), dataType : "json", async : false, success : function(data) {
                var result = data.split("/");
                for (var i = 0; i < result.length; i++) {
                    //-- result[0]:DealId , result[1]:Return Message
                    result[i];
                    //alert(result[i]);
                }

                if (typeof result[1] == "undefined") {
                    //-- SUCCESS
                    varResult.result = "true"; // true/false
                    //varResult.msg = ""; // 메시지
                } else {
                    //-- ERROR
                    varResult.result = "false"; // true/false
                    varResult.msg = result[1]; // 메시지
                }
            }, error : function() {
                varResult.result = "false"; // true/false
                varResult.msg = "<spring:message code="message.error"/>"; // 메시지
            }});
        }

        if (varResult.result == "false") {
            autoAppResult = "N";
            alert(varResult.msg);
        } else {
            //-- iFrame Reload.
            //결재IFrame없애며 주석처리(2017.1.10)
            //$('#frame_approval').prop("src", "${pageContext.request.contextPath}/approval.do?doc_id=" + document.getElementById('docId').value);
            
            if ($('#doc_id').val() != $('#docId').val()){
            	$('#doc_id').val($('#docId').val());
            	initApproval();
            }
            
            doAction("SearchStage");
        }
    }

    /*------------------------------------------------------------------------
     *  Desc. : Input Box에 숫자만 입력
     *------------------------------------------------------------------------*/
    $(document).on("keyup", "input:text[numberOnly]", function() {
        $(this).val($(this).val().replace(/[^0-9]/gi, ""));
    });

    $(document).ready(function() {
        
        if (!loaded){
            loaded = true;
        }
        
        unbindLink.start();
        
        viewPDFComponent();
    });
    var loaded = false;
    //PDF View조회(24 jan 2017)
    var isLodingErrorPDF = true;   //PDF조회가 정상로딩여부
    function viewPDFComponent(){
    	//PDF내용 보여주기(최초)
    	var htmlElement = '';
        if (!isLodingErrorPDF){
            return;
        }
    	
        $.ajax({
			type : 'POST',
			url : 'PDFSearchView.do',
			data : {docNo:$('#docId').val()},
			dataType : "json",
			async : true,
			success : function(data) {
						
	    		if (data){
		    		var pattern = /<body[^>]*>((.|[\n\r])*)<\/body>/ig; //fatch body tag from result
		    		var html = data.match(pattern);
		    		
                    $('.PDFComponent1').unbind();
                    $('.PDFComponent1').html(html); //replace html
                    
                    //bind to Valuation Link
                    $('.PDFComponent1 a').bind('click', function(e){
                        e.preventDefault();
                        openPopup('linkValuId');
                    });

                    if (showMode === mode.lookAt.VIEW){
                        $(".notEquipComponent,.equipComponent").hide();
                        $('.outerContainer').show();
                    }                    
	    		}
	    		unbindLink.end();
			},
			error : function(e) {
				unbindLink.end();
                isLodingErrorPDF = false;
                var pattern = /(\\n|\\r)/g;
                
                var jsonmsg = e.responseText.replace(pattern, '<br>');
                try {
                    var JSon = JSON.parse(jsonmsg.replace(/'/g, '"'));
                    jsonmsg = JSon.Result.Message;
                } catch(e) {}
                
                htmlElement = '<h3>Loading PDF <spring:message code="message.error"/></h3><br>' + (jsonmsg ? jsonmsg:'');
                $('.PDFComponent1').html(htmlElement); //replace html
			}
		});
    	
    }

    
    /*------------------------------------------------------------------------
     *  Event : $(document).ready(function()
     *  Desc. : 화면 띄울때 크기 재조정(22 jan 2017)
     *------------------------------------------------------------------------*/
    function lfn_ResizeSheet() {
         var inputFieldWidth = $(".inquiryWrap").innerWidth();
         /*[추가-시작]각화면에서 조절할것*/
         //mySheetAttachFile.SetSheetWidth(inputFieldWidth);    //자동으로 늘어남으로 불필요 하여 주석
         mySheetAttachFile.SetSheetHeight(150);
         /*[추가-끝]*/        
        
        if (sheetHeight){   //장비최대화 클릭후
			if (equipMode === mode.full.EQUIP && showMode === mode.lookAt.EDIT){//장비최대화이고 수정모드일때
			
				var conWrapH = $(".containerWrap").height();
	            var winH =  $(parent.document).find("body").height();
	            var headerH = $(parent.document).find("header").height();
	            var footerH = $(parent.document).find("footer").height();
	            var inquiryH = $(".inquiryWrap").height();
	            var eqHeaderH  = $(".equipComponent .panel-heading").height();            
	            var height = winH -headerH - footerH - inquiryH - eqHeaderH - 110;
	            
                //console.log('화면최대화+큰화면이동:'+height);
	            if (height < 250){ height = 250;}
	            
	            $("#equipLists").height(height);
	            mySheetEquip.SetSheetHeight(height);
				
			}
			else{
				$("#equipLists").height(sheetHeight);
				mySheetEquip.SetSheetHeight(sheetHeight)
			}
        }
    }
    
</script>
</head>

<body>
    <style>
		input.impt {
		  background-color: #fff5da !important;
		}
		
		select.impt {
		  background-color: #fff5da !important;
		}
		
		.inquiryWrap .inputField2 .inputList div span {
		  text-indent: 0px;
		}
		.pdfColWrap { float:left; padding: 2px 10px; }
		.pdfColWrap label { margin: 0 10px; color:#5bc0de; }

		/* PDF Viewer */
		.PDFComponentWrap {
			width:100%; background:#ffffff; border:0px solid #ffffff; margin:10px auto;
		}
		.PDFComponent1 {
			width:780px; border:1px solid #ffffff; padding:10px; margin:0 auto; height:100%; min-height:800px;overflow-y:auto;
		}
		.PDFComponent1 th, .PDFComponent1 td {
			padding:4px; font-size:10pt;
		}

        /* Attach Sheet */
        #fileAttach { margin-bottom:10px; }
	</style>
    <!-- ============================================= -->
    <!-- outer Container -->
    <section class="outerContainer clearfix brBottom1">

        <!-- ================== Tree ===================== -->
        <!-- 클라스 'open' 으로 열림, 닫힘 조절 :  open 일때 left 0px, 'open' 클라스 없을경우 left: -198px -->
        <section class="open tree_lnb" style="width:268px">
            <script>createIBSheetFix("mySheetTree", "100%", "100%");</script>
            <div class="cDs_open">
                <a class="close_lnb ">close tree menu</a>
            </div>
            <div class="cDs_close" style="display: none;">
                <a class="open_lnb ">open tree menu</a>
            </div>
        </section>
        <!-- Tree End-->

        <!-- Container -->
        <section class="containerWrap clearfix dashboard">

            <!-- ======================================= -->
            <form name='popFrm' id='popFrm'>
                <!-- 조회조건의 PopUp -->
                <input type="hidden" name="PopGbn" id="PopGbn" />
                <input type="hidden" name="searchId" id="searchId" />
                <input type="hidden" name="Company" id="Company" />
                <input type="hidden" name="CompanyNm" id="CompanyNm" />
                <input type="hidden" name="DealType" id="DealType" />
                <input type="hidden" name="DocType" id="DocType" />
                <input type="hidden" name="DocDetailType" id="DocDetailType" />
                <input type="hidden" name="equipList" id="equipList" />
            </form>
            <!-- 결재용 -->
            <form id="frm_approval" name="frm_approval">
			<input name="doc_id" id="doc_id" type="hidden" value="${docId}">
			<input name="refType" id="refType" type="hidden" value="">
			</form>
			<!--// 결재용 -->

            <!-- ======================================= -->
            <form name='Frm' id='Frm' method="post">
                <input type="hidden" name="Id" id="Id"/>
                <input type="hidden" name="approvalStatusCd" id="approvalStatusCd"/>

                <section class="inquiryWrap clearfix">

                    <!-- ================== 결재 영역 ===================== -->
					<!--  결재 영역 -->
					<div id="div_Approval">
						<section class="termsWrap clearfix" style="padding:0px;">
						  <!-- Request -->
						  <div class="inputFiled fl" id="div_Request"></div>				
						  <!-- Reference -->
						  <div class="inputFiled fl" id="div_Reference"></div>				
						  <!-- Leader -->
						  <div class="inputFiled fl" id="div_Leader"></div>				
						  <!-- Management -->
						  <div class="inputFiled fl" id ="div_Management"></div>
						</section>
						<!-- //상단info영역 -->
						<section class="boxWrap clearfix va_cont mt20" style="position: relative;">
							<div class="va_close_bt" style="position: absolute; bottom: -4px; left: 48%; cursor: pointer; width: 48px; height: 10px; display: none;">
								<img src="/KSS/img/ico/va_close_bt.png" />
							</div>
							<div class="va_open_bt" style="position: absolute; bottom: -4px; left: 48%; cursor: pointer; width: 48px; height: 10px;">
								<img src="/KSS/img/ico/va_open_bt.png" />
							</div>
							<div class="va_container" style="display: none;">
								<section class="dataWrap" id="sub_contents" >
									<div id="DIV_mySheetAppr"></div>
								</section>
							</div>
						</section>				
					</div>
					<!-- //결재 영역 -->


                    <!-- ================== PO/INV 영역 ===================== -->
                    <div class="btnArea clearfix mt5">

                        <!-- Test시 확인용....style="display:none"  처리..... -->
                        <div class="inquiryBox f1" style="display:none">

                            <!-- 타 화면과 연계 여부 -->
                            <input type="hidden" id="etcFlag" name="etcFlag" value="${etcFlag}" />
                            <input type="hidden" id="extFlagType" name="extFlagType" value="${extFlagType}" />
                            <!-- ---------------- -->

                            <div class="inquiry deal fl">
                                <h2 class="hidden">selEquip</h2>
                                <div class="selectBoxWrap  fl">
                                    <select class="width120">
                                        <option>selEquip</option>
                                    </select>
                                </div>
                                <input type="hidden" name="subjectCdList" id="subjectCdList" value="" />
                                <input type="hidden" name="selEquip" id="selEquip" value="${selEquip}" />
                                <input type="hidden" name="didList" id="didList" value="${param.didList}" />
                            </div>

                            <div class="inquiry deal fl">
                                <h2 class="hidden">Relation Deal</h2>
                                <div class="selectBoxWrap  fl">
                                    <select class="width120">
                                        <option>Relation Deal</option>
                                    </select>
                                </div>
                                <input class="a" type="text" name="relId" id="relId" value="${relId}" readonly />
                            </div>

                            <div class="inquiry deal fl">
                                <h2 class="hidden">Currency Rev Yn</h2>
                                <div class="selectBoxWrap  fl">
                                    <select class="width120">
                                        <option>Currency Rev Yn</option>
                                    </select>
                                </div>
                                <input class="a" type="text" name="curRev" id="curRev" value="N" readonly />
                            </div>

                            <div class="inquiry deal fl">
                                <h2 class="hidden">User ID.</h2>
                                <div class="selectBoxWrap  fl">
                                    <select class="width120">
                                        <option>User ID.</option>
                                    </select>
                                </div>
                                <input class="a" type="text" name="user" id="user" value="${userId}" readonly />
                            </div>

                            <div class="inquiry deal fl">
                                <h2 class="hidden">Request/Approval</h2>
                                <div class="selectBoxWrap  fl">
                                    <select class="width120">
                                        <option>Request/Approval</option>
                                    </select>
                                </div>
                                <input class="a" type="text" name="strMode" id="strMode" readonly /> <input class="a" type="text" name="dealYn" id="dealYn" readonly />
                                <!-- 결재처리시 동일 Proc. 사용위해 Id 추가...-->
                                <input class="a" type="text" name="dealYn" id="dealYn" readonly />
                            </div>
                            <!-- 파일첨부 -->
                            <input type="text" id="attaGrpId" name="attaGrpId" />
                            <!-- ------- -->
                        </div>
                        <!-- Test시 확인용....style="display:none"  처리..... End -->
                        
                        
		                <div id="fileAttach">

							<div class="btnArea clearfix mt10 vtTop">
								<img alt="" src="/KSS/img/ico/bullet_Tle01.png">
								<span style="font-size: 14px; color: #333; font-weight: bold;">File Attachment</span>
								<div class="fr attaBtn" id="divAttaBtn">									
								</div>
							</div>
							<section class="tableWrap mt10">
								<div id="DIV_mySheetAttachFile">	</div><!-- id는 꼭 이걸로 해야함 -->
							</section>
		                </div>		                
		                
                        <div class="fr" id="docButton">
                            <script>createEditButton("<spring:message code="button.save"/>", "SaveStage")</script>&nbsp;
                        </div>

                        <div class="fr" id="versionUpButton">
                            <script>createQueryButton_text("<spring:message code="button.versionup"/>", "VersionUp")</script>&nbsp;
                        </div>

                        <div class="fr" id="copyButton">
                            <script>createQueryButton_text("<spring:message code="button.copy"/>", "DocCopy")</script>&nbsp;
                        </div>

                        <div class="fr">
                            <script>createQueryButton_text("<spring:message code="button.dealList"/>","Search1")</script>&nbsp;
                        </div>

                        <div class="fr">
                            <script>createQueryButton_text("<spring:message code="button.packagePDF"/>","PackagePDF")</script>&nbsp;
                        </div>
                        
                        <div class="fr">
                        	<script>createQueryButton_text("<spring:message code="button.modify"/>", "Modify")</script>&nbsp;
                        </div>
                    </div>
                    <div class="PDFComponentWrap">
						<div class="panel PDFComponent1"></div>
					</div>                    
                    <section class="boxWrap inputField2 mt8 clearfix notEquipComponent" style="display:none;">
                    <!-- BEFORE -->
                        <div class="row inputList">

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span><strong style="color: #ff6d00;"></strong>Document ID</span>
                                <div class="  ">
                                    <input class="width180P" class="a" type="text" style="text-align: center;" name="docId" id="docId" value="${docId}" readonly />
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span><strong style="color: #ff6d00;"></strong>Document Type</span>
                                <div class="  ">
                                    <select class="width180P impt" name="docTitle" id="docTitle" onchange="onChange('docTitle')">
                                        <c:forEach var="docTitle" items="${docTitles}">
                                            <option value="${docTitle.code}">${docTitle.name}</option>
                                        </c:forEach>
                                    </select>
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span>Deal Type</span> <select class="width180P impt" name="dealType" id="dealType" onchange="onChange('dealType')">
                                    <c:forEach var="dealType" items="${dealTypes}">
                                        <option value="${dealType.code}">${dealType.name}</option>
                                    </c:forEach>
                                </select>
                            </div>

                        </div>

                        <div class="row inputList">

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span>VAT Included</span> <select class="width180P impt" name="vat" id="vat">
                                    <c:forEach var="docVatType" items="${docVatTypes}">
                                        <option value="${docVatType.code}">${docVatType.name}</option>
                                    </c:forEach>
                                </select>
                            </div>


                            <div class="col-lg-3 col-md-4 col-xs-3" id="viewOfferType">
                                <span>Detail Type</span> <select class="width180P impt" name="offerType" id="offerType" onchange="onChange('offerType')">
                                    <c:forEach var="offerType" items="${offerTypes}">
                                        <option value="${offerType.code}">${offerType.name}</option>
                                    </c:forEach>
                                </select>
                            </div>

                            <div class="col-lg-3 col-md-4 col-xs-3" id="viewPoType">
                                <span>Detail Type</span> <select class="width180P impt" name="poType" id="poType">
                                    <option value="">N/A</option>
                                    <c:forEach var="poType" items="${poTypes}">
                                        <option value="${poType.code}">${poType.name}</option>
                                    </c:forEach>
                                </select>
                            </div>

                            <div class="col-lg-3 col-md-4 col-xs-3" id="viewContractType">
                                <span>Detail Type</span> <select class="width180P impt" name="contractType" id="contractType">
                                    <option value="">N/A</option>
                                    <c:forEach var="contractType" items="${contractTypes}">
                                        <option value="${contractType.code}">${contractType.name}</option>
                                    </c:forEach>
                                </select>
                            </div>

                            <div class="col-lg-3 col-md-4 col-xs-3" id="viewInvoiceType">
                                <span>Detail Type</span> <select class="width180P impt" name="invoiceType" id="invoiceType">
                                    <option value="">N/A</option>
                                    <c:forEach var="invoiceType" items="${invoiceTypes}">
                                        <option value="${invoiceType.code}">${invoiceType.name}</option>
                                    </c:forEach>
                                </select>
                            </div>

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span><strong style="color: #ff6d00;"></strong>Document Title</span>
                                <div class="  ">
                                    <input class="width180P impt" type="text" id="docSubj" name="docSubj" maxlength="1000" />
                                </div>
                            </div>

                        </div>
                        <div class="row inputList">

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span id="cidSpan1">From(CID)</span>
                                <div class="  " id="cidDiv1">
                                    <input type="hidden" id="buyCompId" name="buyCompId" readOnly /> <input class="width180P impt" type="text" id="buyCompNm" name="buyCompNm" readOnly /> <a class="input_ico"><img src="./img/ico/ico_search_01.png" id="buyCompIdBtn" name="buyCompIdBtn" onclick="openPopup('buyCompId')" alt="buyCompId" /></a>
                                </div>
                            </div>

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span id="displaySpan1">From(Display)</span>
                                <div class="  " id="displayDiv1">
                                    <input class="width180P" type="text" id="docBuyCompNm" name="docBuyCompNm" maxlength="500" />
                                </div>
                            </div>

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span id="personSpan1">From Person</span>
                                <div class="  " id="personDiv1">
                                    <input type="hidden" id="fromPicPersonId" name="fromPicPersonId" readOnly /> <input class="width180P impt" type="text" id="fromPicPersonNm" name="fromPicPersonNm" readOnly /> <a class="input_ico"><img src="./img/ico/ico_search_01.png" id="fromPicPersonIdBtn" name="fromPicPersonIdBtn"  onclick="openPopup('fromPicPersonId')" alt="fromPicPersonId" /></a>
                                </div>
                            </div>

                        </div>
                        <div class="row inputList">

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span id="personDisplaySpan1">From Person(Display)</span>
                                <div class="  " id="personDisplayDiv1">
                                    <input class="width180P" type="text" id="docFromPicPersonNm" name="docFromPicPersonNm" maxlength="500" />
                                </div>
                            </div>

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span id="cidSpan2">To(CID)</span>
                                <div class="  " id="cidDiv2">
                                    <input type="hidden" id="sellCompId" name="sellCompId" readOnly /> <input class="width180P impt" type="text" id="sellCompNm" name="sellCompNm" readOnly /> <a class="input_ico"><img src="./img/ico/ico_search_01.png" id="sellCompIdBtn" name="sellCompIdBtn" onclick="openPopup('sellCompId')" alt="sellCompId" /></a>
                                </div>
                            </div>

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span id="displaySpan2">To(Display)</span>
                                <div class="  " id="displayDiv2">
                                    <input class="width180P" type="text" id="docSellCompNm" name="docSellCompNm" maxlength="500" />
                                </div>
                            </div>

                        </div>
                        <div class="row inputList">

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span id="personSpan2">To Person</span>
                                <div class="  " id="personDiv2">
                                    <input type="hidden" id="picPersonId" name="picPersonId" readOnly /> <input class="width180P impt" type="text" id="picPersonNm" name="picPersonNm" readOnly /> <a class="input_ico"><img src="./img/ico/ico_search_01.png" id="picPersonIdBtn" name="picPersonIdBtn"  onclick="openPopup('picPersonId')" alt="picPersonId" /></a>
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-xs-3" id="docToPicPersonNmDiv">
                                <span id="personDisplaySpan2">To Person(Display)</span>
                                <div class="  " id="personDisplayDiv2">
                                    <input class="width180P" type="text" id="docPicPersonNm" name="docPicPersonNm" maxlength="500" />
                                </div>
                            </div>

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span><strong style="color: #ff6d00;"></strong>Issue Date</span>
                                <div>
                                    <input class="width180P impt dateCheckForm" type="text" style="text-align: center;" id="stageDate" name="stageDate" maxlength="8" numberonly="true" />
                                    <a href="javascript:IBCalendar.Show($('#stageDate').val(), {Format:'yyyyMMdd', Target:'Mouse', CallBack:'setStageDate', CalButtons:'Close'});"> <img src="./img/ico/ico_calendar.png" alt="stageDate" /></a>
                                </div>
                            </div>

                        </div>
                        <div class="row inputList">

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span>Currency</span>
                                <div class="  ">
                                    <select class="width180P impt" name="currency" id="currency" onchange="onChange('currency')">
                                        <c:forEach var="currency" items="${currencys}">
                                            <option value="${currency.code}">${currency.name}</option>
                                        </c:forEach>
                                    </select>
                                </div>
                            </div>

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span>Total Amount</span>
                                <div class="fl input size2">
                                    <input class="width180P" type="text" value="0" style="text-align: right;" id="equipAmount" name="equipAmount" readOnly />
                                </div>
                            </div>

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span>Deal ID</span>
                                <div class="  ">
                                    <input class="width180P" type="text" style="text-align: center;" id="opptId" name="opptId" readOnly />
                                </div>
                            </div>

                        </div>
                        <div class="row inputList">

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span><strong style="color: #ff6d00;"></strong>Exchange Date</span>
                                <div class="  ">
                                    <input class="width180P impt dateCheckForm" type="text" style="text-align: center;" id="exDate" name="exDate" maxlength="8" numberonly="true" /> <a href="javascript:IBCalendar.Show($('#exDate').val(), {Format:'yyyyMMdd', Target:'Mouse', CallBack:'setExDate', CalButtons:'Close'});"> <img src="./img/ico/ico_calendar.png" alt="exDate" /></a>
                                </div>
                            </div>

                            <div class="col-lg-3 col-md-4 col-xs-3">
                                <span>Exchange Rate</span>
                                <div class="  ">
                                    <input class="width180P" type="text" id="exRate" name="exRate" style="text-align: right;" onchange="onChange('exRate')" numberonly="true" />
                                </div>
                            </div>

                            <div class="col-lg-3 col-md-4 col-xs-3" id="valuationDiv">
                                <span>Valuation ID</span>
                                <div class="  ">
                                    <input type="hidden" id="valuId" name="valuId"/>
                                    <input type="hidden" id="valuVerId" name="valuVerId"/>
                                    <input type="hidden" id="simulId" name="simulId"/>
                                    <input class="width180P impt" style="cursor:hand" type="text" id="dispValuId" name="dispValuId" onclick="openPopup('linkValuId')" readOnly /> <a class="input_ico"><img src="./img/ico/ico_search_01.png" onclick="openPopup('dispValuId')" alt="dispValuId" /></a>
                                </div>
                            </div>

                            <div class="col-lg-3 col-md-4 col-xs-3" id="preVerDiv">
                                <span>Previous ID</span>
                                <div class="  ">
                                    <input class="width180P" type="text" id="preVerDocId" name="preVerDocId" readOnly disabled />
                                </div>
                            </div>
                        </div>
                        <div class="row inputList">
                            <div class="col-lg-6 col-md-8 col-xs-6">
                                <span>Remark</span>
                                <div>
                                    <input style="width:600px" type="text" id="remark" name="remark" maxlength="4000" />
                                </div>
                            </div>
                            
                            <div class="col-lg-6 col-md-4 col-xs-6">
                                <span>Document ID(Display)</span>
                                <div class="  ">
                                    <input class="width180P" type="text" id="customerDocId" name="customerDocId" maxlength="500" value="${docId}"/>
                                </div>
                            </div>
                        </div>
                    <!-- //BEFORE -->
                    </section>
                    <!-- PO/INV 영역 End -->
                    
                </section>

				<!-- Equip List -->
				<div class="panel panel-default mt20 equipComponent" style="display:none;">
					<div class="panel-heading" style="padding-bottom:0">
						<div class="btnArea clearfix">
		                    <div class="fl" style="width:100%;">
		                        <img alt="" src="/KSS/img/ico/bullet_Tle01.png">
								<span>Equipment List</span>
								<button class="btn btn-info small btnEquipsView" type="button" data-target="equipLists">Show</button>
		                    </div>
		                	<div class="pdfColWrap" style="margin:4px 0 0 0;">
		                		<label>PDF Print</label>
		                		<input type="checkbox" id="pdf0" name="pdfColVal" value="EQUIP_COL:SGNO"/><label for="pdf0">SG NO</label>
		                		<input type="checkbox" id="pdf1" name="pdfColVal" value="EQUIP_COL:SERIAL"/><label for="pdf1">Serial</label>
		                		<input type="checkbox" id="pdf2" name="pdfColVal" value="EQUIP_COL:VINTAGE"/><label for="pdf2">Vintage</label>
		                		<input type="checkbox" id="pdf3" name="pdfColVal" value="EQUIP_COL:PROCESS"/><label for="pdf3">Process</label>
		                		<input type="checkbox" id="pdf4" name="pdfColVal" value="EQUIP_COL:DESCRIPTION"/><label for="pdf4">Description</label>
		                		<input type="checkbox" id="pdf5" name="pdfColVal" value="EQUIP_COL:CODE"/><label for="pdf5">Code</label>
		                		<input type="checkbox" id="pdf6" name="pdfColVal" value="EQUIP_COL:BIDNO"/><label for="pdf6">Bid No</label>
		                		<input type="checkbox" id="pdf7" name="pdfColVal" value="ETC_COL:ATTACH"/><label for="pdf7">Attach Equip</label>
		                		<input type="checkbox" id="pdf8" name="pdfColVal" value="ETC_COL:PRICE"/><label for="pdf8">Unit Price</label>
		                	</div>
		                    <div class="fr">		                    	
		                        <script>createEditButton("<spring:message code="button.createPay"/>", "CreatePayment")</script>
		                        <script>createEditButton("<spring:message code="button.createShip"/>", "CreateShipment")</script>&nbsp;
		                        <div class="fr" id="equipButton">
		                            <script>createQueryButton_text("<spring:message code="button.selEquip"/>", "SelEquip")</script>&nbsp;
		                        </div>
		                        <div class="fr" id="refurbButton">
		                            <script>createEditButton("<spring:message code="button.refurbSource"/>", "RefurbSource")</script>&nbsp;
		                        </div>
		                    </div>
	                    </div>
					</div>
					<div class="panel-body">
						<div id="equipLists" class="row" style="height:250px;">
		                    <script>createIBSheet("mySheetEquip", "100%", "250px");</script>
						</div>
					</div>
				</div>
				<!-- Equip List //-->

                <div style="display:none">
                    <script>createIBSheetFix("mySheet", "100%", "100%");</script>
                </div>
                <!-- Equipment End -->

                <!-- Payment Terms -->
				<div class="panel panel-default mt20 notEquipComponent" style="display:none;">
					<div class="panel-heading" style="padding-bottom:0">
						<div class="btnArea clearfix">
		                    <div class="fl" style="width:100%">
		                        <img alt="" src="/KSS/img/ico/bullet_Tle01.png">
								<span>Payment Terms</span>
								<button class="btn btn-info small btnPayTermsView" type="button" data-target="payTerms">Hide</button>
		                    </div>
		                	<div class="pdfColWrap" style="margin:4px 0 0 0;">
		                		<label>PDF Print</label>
		                		<input type="checkbox" id="pdf9" name="pdfColVal" value="PAY_TERMS_COL:AMOUNT"/><label for="pdf9">%/Amount</label>
		                		<input type="checkbox" id="pdf10" name="pdfColVal" value="PAY_TERMS_COL:BY"/><label for="pdf10">By</label>
		                		<input type="checkbox" id="pdf11" name="pdfColVal" value="PAY_TERMS_COL:WDAY"/><label for="pdf11">within Days</label>
		                		<input type="checkbox" id="pdf12" name="pdfColVal" value="PAY_TERMS_COL:BPROCESS"/><label for="pdf12">Business Process</label>
		                		<input type="checkbox" id="pdf13" name="pdfColVal" value="PAY_TERMS_COL:DUEDATE"/><label for="pdf13">Due Date</label>
		                		<input type="checkbox" id="pdf14" name="pdfColVal" value="PAY_TERMS_COL:REMARK"/><label for="pdf14">Remark</label>
		                	</div>
		                    <div class="fr" id="paymentButton">
		                        <script>createEditButton("<spring:message code="button.add"/>", "AddPay")</script>
		                    </div>
	                    </div>
					</div>
					<div class="panel-body">
						<div id="payTerms" class="row">
		                    <script>createIBSheet("mySheetPay", "100%", "140px");</script>
						</div>
					</div>
				</div>				
                <!-- Payment Terms //-->
                
                <!-- Package PDF -->
				<div class="panel panel-default mt20 notEquipComponent" style="display:none;">
					<div class="panel-heading">
						<div class="btnArea clearfix">
		                    <div class="fl">
		                        <img alt="" src="/KSS/img/ico/bullet_Tle01.png">
								<span>Package PDF</span>
								<button class="btn btn-info small btnPdfView" type="button" data-target="pdfs">Hide</button>
		                    </div>		                		
	                        <div class="fr">
		                        <script>createEditButton("<spring:message code="button.add"/>", "AddPdf")</script>
		                    </div>
		                    <div class="pdfColWrap" style="float:right;"><label style="color: #F44336;">Remain Amount</label><span id="pdfRemainAmount" style="margin-right:30px;overflow:visible;color: #F44336;"></span></div>
	                    </div>
					</div>
					<div class="panel-body">
						<div id="pdfs" class="row">
		                    <script> createIBSheet("mySheetPdf", "100%", "200px");</script>
						</div>
					</div>
				</div>

                <!-- Package PDF //-->

                <!-- ================== Terms And Conditions ===================== -->
                <section class="boxWrap inputField2 mt8 clearfix notEquipComponent" style="display:none;">
                    <table class="dataTable">
                        <colgroup>
                            <col style="width:200px;" />
                            <col style="width:180px;" />
                            <col style="width:160px;" />
                            <col style="width:*;" />
                        </colgroup>
                        <tr>
                            <th><input type="hidden" id="priceTermYn" name="priceTermYn" value="Y"/><input type="checkbox" id="chk_priceTerm" name="chk_priceTerm" value="1" checked style="opacity: 100;" />&nbsp;Price Term</th>
                            <td>
                                <select style="width:160px;" name="priceTerms" id="priceTerms">
                                	<option value=""></option>
                                    <c:forEach var="priceTerms" items="${priceTermss}">
                                        <option value="${priceTerms.code}">${priceTerms.name}</option>
                                    </c:forEach>
                                  </select>
                            </td>
                            <td colspan="2" style="padding-right:0">
                                <select style="width:160px;" name="priceCountry" id="priceCountry">
                                	<option value=""></option>
                                    <c:forEach var="priceCountry" items="${priceCountrys}">
                                        <option value="${priceCountry.code}">${priceCountry.name}</option>
                                    </c:forEach>
                                </select>
                                <input type="text" id="priceRemark" name="priceRemark" maxlength="4000" style="width: 616px;" />
                            </td>
                        </tr>
                        <tr>
                            <th><input type="hidden" id="deliveryYn" name="deliveryYn" value="Y"/><input type="checkbox" id="chk_delivery" name="chk_delivery" value="1" checked style="opacity: 100;" />&nbsp;Delivery</th>
                            <td colspan="3"> <input type="text" id="deliText" name="deliText" maxlength="1000" style="width: 960px;" /></td>
                        </tr>
                        <tr>
                            <th><input type="hidden" id="packTypeYn" name="packTypeYn" value="Y"/><input type="checkbox" id="chk_packType" name="chk_packType" value="1" checked style="opacity: 100;" />&nbsp;Packaging Type</th>
                            <td>
                                 <select style="width:160px;" name="packType" id="packType">
                                 	<option value=""></option>
                                    <c:forEach var="packType" items="${packTypes}">
                                        <option value="${packType.code}">${packType.name}</option>
                                    </c:forEach>
                                 </select>
                            </td>
                            <td colspan=2>
                                <input type="text" id="packRemark" name="packRemark" maxlength="4000" style="width: 780px;" />
                            </td>
                        </tr>                       
                        <tr>
                            <th><input type="hidden" id="packResYn" name="packResYn" value="Y"/><input type="checkbox" id="chk_packRes" name="chk_packRes" value="1" checked style="opacity: 100;" />&nbsp;Packaging Responsibility</th>
                            <td colspan="3">
                                <select style="width:160px;" name="pcakRespon" id="pcakRespon">
                                	<option value=""></option>
                                    <c:forEach var="pcakRespon" items="${pcakRespons}">
                                        <option value="${pcakRespon.code}">${pcakRespon.name}</option>
                                    </c:forEach>
                                </select>
                            </td>
                        </tr>
                        <tr>
                            <th><input type="hidden" id="warrTermYn" name="warrTermYn" value="Y"/><input type="checkbox" id="chk_warrTerm" name="chk_warrTerm" value="1" checked style="opacity: 100;" />&nbsp;Warranty Term</th>
                            <td>
                                <select name="warTerms" id="warTerms">
                                	<option value=""></option>
                                    <c:forEach var="warTerms" items="${warTerms}">
                                        <option value="${warTerms.code}">${warTerms.name}</option>
                                    </c:forEach>
                                  </select>
                            </td>
                            <th><input type="hidden" id="warrLaborYn" name="warrLaborYn" value="Y"/><input type="checkbox" id="chk_warrLabor" name="chk_warrLabor" value="1" checked style="opacity: 100;" />&nbsp;Labor</th>
                            <td><input type="text" id="warLaborPeriod" name="warLaborPeriod" maxlength="500" style="width:130px; margin-right:3px;" /><input type="text" id="warLaborRemark" name="warLaborRemark" maxlength="4000" style="width: 370px;" /> <input class="dateCheckForm" type="text" style="text-align: center; width: 80px;" id="warLaborDt" name="warLaborDt" maxlength="8" numberonly="true" /> <a href="javascript:IBCalendar.Show($('#warLaborDt').val(), {Format:'yyyyMMdd', Target:'Mouse', CallBack:'setWarLaborDt', CalButtons:'Close'});"> <img src="./img/ico/ico_calendar.png" alt=warLaborDt /></a></td>
                        </tr>
                        <tr>
                            <th></th>
                            <td></td>
                            <th><input type="hidden" id="warrPartYn" name="warrPartYn" value="Y"/><input type="checkbox" id="chk_warrPart" name="chk_warrPart" value="1" checked style="opacity: 100;" />&nbsp;Part</th>
                            <td><input type="text" id="warPartPeriod" name="warPartPeriod" maxlength="500" style="width:130px; margin-right:3px;"  /><input type="text" id="warPartRemark" name="warPartRemark" maxlength="4000" style="width: 370px;" /> <input class="dateCheckForm" type="text" style="text-align: center; width: 80px;" id="warPartDt" name="warPartDt" maxlength="8" numberonly="true" /> <a href="javascript:IBCalendar.Show($('#warPartDt').val(), {Format:'yyyyMMdd', Target:'Mouse', CallBack:'setWarPartDt', CalButtons:'Close'});"> <img src="./img/ico/ico_calendar.png" alt="warPartDt" /></a></td>
                        </tr>
                        <tr>
                            <th><input type="hidden" id="shipYn" name="shipYn" value="Y"/><input type="checkbox" id="chk_ship" name="chk_ship" value="1" checked style="opacity: 100;" />&nbsp;Shipment By</th>
                            <td>
                                 <select style="width:160px;" name="shipBy" id="shipBy">
                                 	<option value=""></option>
                                     <c:forEach var="shipBy" items="${shipBys}">
                                         <option value="${shipBy.code}">${shipBy.name}</option>
                                     </c:forEach>
                                 </select>
                             </td>
                             <td colspan=2>                                        
                                <input type="text" id="shipByRemark" name="shipByRemark" maxlength="4000" style="width: 780px;" />
                            </td>
                        </tr>
                        <tr>
                            <th><input type="hidden" id="bankYn" name="bankYn" value="Y"/><input type="checkbox" id="chk_bank" name="chk_bank" value="1" checked style="opacity: 100;" />&nbsp;Seller's Bank Account</th>
                            <td style="vertical-align:top"">
                                <select style="width:160px;" name="sellBnk" id="sellBnk">
                                	<option value="" desc=""></option>
	                                <c:forEach var="sellBnk" items="${sellBnks}">
	                                    <option value="${sellBnk.code}" desc="${sellBnk.ref01Desc}">${sellBnk.name}</option>
	                                </c:forEach>
                                </select>
                            </td>
                            <td colspan="2">
                                <textarea id="sellBnkRemark" name="sellBnkRemark" maxlength="4000" rows="7" style="width:780px;overflow:hidden;line-height:normal" disabled></textarea>
                            </td>
                            
                        </tr>
                        <tr>
                            <th><input type="hidden" id="validityYn" name="validityYn" value="Y"/><input type="checkbox" id="chk_validity" name="chk_validity" value="1" checked style="opacity: 100;" />&nbsp;Validity</th>
                            <td colspan="3"><input type="text" class="impt dateCheckForm" style="text-align: center; width:160px;" name="valDate" id="valDate" maxlength="8"> <a href="javascript:IBCalendar.Show($('#valDate').val(), {Format:'yyyyMMdd', Target:'Mouse', CallBack:'setValDate', CalButtons:'Close'});" style="margin-left:-25px;"> <img src="./img/ico/ico_calendar.png" /></a></td>
                        </tr>                        
                        <tr id="subPriorSalesYnDiv">
                            <th>Subject to Prior Sales</th>
                            <td colspan="3">
                                <select style="width:160px;" name="subPriorSalesYn" id="subPriorSalesYn">
                                    <option value="Y">Y</option>
                                    <option value="N">N</option>
                                </select>
                            </td>
                        </tr>
                        <tr>
                            <th><input type="hidden" id="remarkYn" name="remarkYn" value="Y"/><input type="checkbox" id="chk_remark" name="chk_remark" value="1" checked style="opacity: 100;" />&nbsp;Remark</th>
                            <td colspan="3"><textarea id="termsRemark" name="termsRemark" rows="5" maxlength="4000" style="width: 961px;overflow:scroll; line-height:normal"></textarea></td>
                        </tr>
                    </table>
                
                </section>

            </form>
            <!-- form name='Frm' End -->

        </section>
        <!-- Container End -->

    </section>
    <!-- // outer Container end-->   


</body>
</html>