$(document).ajaxStart(function(){
    $("#loading").show();
}).ajaxStop(function(){
    $("#loading").hide();
});

$(function () {
    $("#psi2eliform").submit(function (event) {
        var psi = $("#psi").val();
        $("#ELI").html("<b>Please wait for the search for identifier " + psi + " to complete</b>");
        $.ajax({
            url: "/" + psitype + "2eli/" + encodeURIComponent(psi),
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