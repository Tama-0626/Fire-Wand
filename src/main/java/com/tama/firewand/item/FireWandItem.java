package com.tama.firewand.item;

import net.minecraft.world.entity.player.Player;
import net.minecraft.world.entity.projectile.hurtingprojectile.SmallFireball;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.phys.Vec3;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;

public class FireWandItem extends Item {
	private static final int COOLDOWN_TICKS = 20;

	public FireWandItem(Item.Properties settings) {
		super(settings);
	}

	@Override
	public InteractionResult use(Level level, Player user, InteractionHand hand) {
		ItemStack stack = user.getItemInHand(hand);

		if (!level.isClientSide()) {
			Vec3 direction = user.getViewVector(1.0F);
			SmallFireball fireball = new SmallFireball(level, user, direction);
			fireball.setPos(user.getX(), user.getEyeY() - 0.1, user.getZ());
			fireball.setDeltaMovement(direction.scale(1.5));
			level.addFreshEntity(fireball);
			level.playSound(null, user.blockPosition(), SoundEvents.BLAZE_SHOOT,
					SoundSource.PLAYERS, 1.0F, 1.0F);
			user.getCooldowns().addCooldown(stack, COOLDOWN_TICKS);
		}

		return InteractionResult.SUCCESS;
	}
}
