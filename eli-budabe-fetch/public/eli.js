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
            var uricomponent = '/celex/';
        } else {
            var uricomponent = '/oj/';
        };
        var encodedPSI =  encodeURIComponent("http://publications.europa.eu/resource" + uricomponent + psi).replace(/\(/g, "%28").replace(/\)/g, "%29");
        $("#ELI").html("<b>Please wait for the search for identifier " + psi + " to complete</b>");
        $.ajax({
            url: "/eli4psi/" + encodedPSI,
            type: "GET",
            dataType : "json",
            async : true,
            success: function( json ) {
                var eli = JSON.stringify(json);
                var eli_msg = "Your ELI is: <b><a href=" + eli + "\>" + eli + "</a></b><br/> See here the corresponding <a href=\"/eli4psi/" + encodedPSI + "/metadata\">RDFa-enriched metadata</a>  (might take a moment to load)";
                alert(eli_msg);
                $("#ELI").html(eli_msg);
            },
            error: function( xhr, status ) {
                alert(status);
                $("#ELI").html("<b>" + xhr.responseText + "</b>");
            },
        });
        return false;
    });
});
