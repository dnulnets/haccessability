//
// The Openlayers Vector API mapping for purescript.
//
// This is just a very crude mapping and only helps out with what I need for this application. It is no
// complete mapping.
//
// Written by Tomas Stenlund, Sundsvall, Sweden (c) 2020
//
"use strict";

// Get hold of the OpenLayer types and functions
var ol  = require ('ol');
var oll  = require ('ol/layer');

exports.createImpl = function (opt) {
    return function() {
        console.log ('Vector.create:', opt)
        var r = new oll.Vector(opt);
        console.log ('Vector.create.return:', r)
        return r; 
    }
}

exports.setStyleImpl = function (s, self) {
    return function() {
        console.log ('Vector.setStyle:', s, self)
        self.setStyle(s);
    }
}
exports.setStyleFImpl = exports.setStyleImpl
exports.setStyleAImpl = exports.setStyleImpl