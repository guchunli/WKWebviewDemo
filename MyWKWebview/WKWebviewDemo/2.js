window.onload=function(){

	alert("window load finish");
    var btn = document.getElementsByTagName('input')[0];
    btn.onclick=function(){
        window.webkit.messageHandlers.nativeMethod.postMessage('js-oc','111');
    }
}

function jsFunc(a){

    alert('OC  调用了 JS jsFunc 方法，传回参数 '+a);
}

