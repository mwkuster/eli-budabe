$(document).ajaxStart(function(){
    $("#loading").show();
}).ajaxStop(function(){
    $("#loading").hide();
});

$(function () {
    $("#psi2eliform").submit(function (event) {
        var psi = $("#psi").val();
        var psitype = $("input[name=psitype]:radio:checked").val();
        if(psitype == 'celex') {
            var uricomponent = '/eli4celex/';
        } else {
            var uricomponent = '/eli4id_jo/';
        };
        var encodedPSI =  encodeURIComponent(psi).replace(/\(/g, "%28").replace(/\)/g, "%29");
        $("#ELI").html("<b>Please wait for the search for identifier " + psi + " to complete</b>");
        $.ajax({
            url: uricomponent + encodedPSI,
            type: "GET",
            dataType : "json",
            async : true,
            success: function( json ) {
                $("#ELI").html("Your ELI is: <b>" + JSON.stringify(json) + "</b>");
            },
            error: function( xhr, status ) {
                $("#ELI").html("<b>" + xhr.responseText + "</b>");
            },
        });
        return false;
    });
});