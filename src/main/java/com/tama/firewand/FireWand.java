package com.tama.firewand;

import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.creativetab.v1.CreativeModeTabEvents;

import net.minecraft.core.Registry;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.core.registries.Registries;
import net.minecraft.resources.ResourceKey;
import net.minecraft.resources.Identifier;
import net.minecraft.world.item.CreativeModeTabs;
import net.minecraft.world.item.Item;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.tama.firewand.item.FireWandItem;

public class FireWand implements ModInitializer {
	public static final String MOD_ID = "fire-wand";
	public static final ResourceKey<Item> FIRE_WAND_KEY = ResourceKey.create(Registries.ITEM, id("fire_wand"));
	public static final Item FIRE_WAND = Registry.register(BuiltInRegistries.ITEM, FIRE_WAND_KEY,
			new FireWandItem(new Item.Properties().setId(FIRE_WAND_KEY)));

	// This logger is used to write text to the console and the log file.
	// It is considered best practice to use your mod id as the logger's name.
	// That way, it's clear which mod wrote info, warnings, and errors.
	public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

	@Override
	public void onInitialize() {
		CreativeModeTabEvents.modifyOutputEvent(CreativeModeTabs.COMBAT).register(output -> output.accept(FIRE_WAND.getDefaultInstance()));
		LOGGER.info("Fire Wand initialized");
	}

	public static Identifier id(String path) {
		return Identifier.fromNamespaceAndPath(MOD_ID, path);
	}
}
