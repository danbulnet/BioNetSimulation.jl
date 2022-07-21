using Makie
import Rotations

function transformations(object)
    translation = object.transformation.translation.val
    rotation = object.transformation.rotation.val
    angle = Makie.quaternion_to_2d_angle(rotation)
    scale = object.transformation.scale.val
    Dict(
        :translation =>translation, 
        :rotation => rotation, 
        :angle => angle,
        :scale => scale
    )
end

function meshgeometry(mesh::Makie.Mesh; transformations=true)
    translation = mesh.parent.transformation.translation.val
    rotation = mesh.parent.transformation.rotation.val
    hyperrectangle = mesh.input_args[1].val

    origin = hyperrectangle.origin
    center = hyperrectangle.origin .+ hyperrectangle.widths / 2
    ending = hyperrectangle.origin .+ hyperrectangle.widths

    if transformations
        origin = rotation * origin
        origin = origin .+ translation
        center = rotation * center
        center = center .+ translation
        ending = rotation * ending
        ending = ending .+ translation
    end

    Dict(
        :origin => Point(origin...), 
        :center => Point(center...),
        :widths => Point(ending .- origin)
    )
end

circlel2r(l::Number) = 0.5l / 2π
circler2l(r::Number) = 2π * r

circley(x::Number, r::Number) = √(r^2 - x^2)

function circlegeometry(lcurrent::Number, ltotal::Number)
    r = circlel2r(ltotal)
    lnorm = lcurrent / ltotal
    α = lnorm * 2π
    x = cos(α) * r
    ysign = (lnorm > 1 // 2 && lnorm < 1) ? -1 : 1
    (x, ysign * circley(x, r), α)
end

function cartesianquarter(center::Point3, point::Point3)::Symbol
    cartesianquarter(Point2(center[1], center[2]), Point2(point[1], point[2]))
end

function cartesianquarter(center::Point2, point::Point2)::Symbol
    if point[1] >= center[1]
        if point[2] >= center[2]
            :I
        else
            :IV
        end
    else
        if point[2] >= center[2]
            :II
        else
            :III
        end
    end
end

function cartesianquarter45(center::Point3, point::Point3)::Symbol
    cartesianquarter45(Point2(center[1], center[2]), Point2(point[1], point[2]))
end

function cartesianquarter45(center::Point2, point::Point2)::Symbol
    yaxispositive = axispositive(point[1], center)
    yaxisnegative = axisnegative(point[1], center)
    if point[2] >= yaxispositive
        if point[2] >= yaxisnegative
            :I
        else
            :II
        end
    else
        if point[2] >= yaxisnegative
            :IV
        else
            :III
        end
    end
end

axispositive(x::Number, center::Point2) = x - (center[1] - center[2])
axisnegative(x::Number, center::Point2) = -x + (center[1] + center[2])